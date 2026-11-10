#!/bin/sh
# Build and run the C++ unit tests of LuneOS.Service's plugin.
#
#   X86_WORKDIR=<tmp/work/corei7-64-webos-linux/luneos-components/<ver>> \
#       ./run-tests.sh [host|asan|tsan|valgrind|sysroot] [gtest arguments...]
#
# The tests run the real LunaServiceAdapter against fake_ls2.cpp, which stands
# in for luna-service2 and webos-application, so no hub is needed. Only their
# headers, and gtest, come from the x86-64 recipe sysroot.
#
#   host      host g++ and the host's Qt 6 (the default)
#   asan      the same with AddressSanitizer and UndefinedBehaviorSanitizer
#   tsan      the same with ThreadSanitizer, one test per process: TSan aborts
#             in its own thread registry when a second QQmlEngine starts its
#             type loader thread in one process. Its reports from inside Qt's
#             loader thread come from an uninstrumented Qt.
#   valgrind  the host build under memcheck; fails on any error or definite leak
#   sysroot   the Yocto cross g++ against the device's Qt, run on the host
#             through the sysroot's own loader
#
# CXX picks the host compiler (default g++), e.g. CXX=clang++ ./run-tests.sh asan.
set -e

MODE=${1:-host}
[ $# -gt 0 ] && shift

if [ -z "$X86_WORKDIR" ] || [ ! -d "$X86_WORKDIR/recipe-sysroot" ]; then
    echo "set X86_WORKDIR to the corei7-64 workdir of the luneos-components recipe" >&2
    exit 1
fi

HERE=$(cd "$(dirname "$0")" && pwd)
PLUGIN=$HERE/../../modules/LuneOS/Service/plugin
SR=$X86_WORKDIR/recipe-sysroot
OUT=$HERE/build/$MODE-$(basename "${CXX:-g++}")
mkdir -p "$OUT/inc"

SOURCES="$PLUGIN/lunaserviceadapter.cpp $OUT/moc_lunaserviceadapter.cpp \
         $HERE/fake_ls2.cpp $HERE/tst_lunaservice_deferred.cpp"

if [ "$MODE" = sysroot ]; then
    NATIVE=$X86_WORKDIR/recipe-sysroot-native
    GXX="$NATIVE/usr/bin/x86_64-webos-linux/x86_64-webos-linux-g++ --sysroot=$SR"
    QTINC="-I$SR/usr/include -I$SR/usr/include/QtCore -I$SR/usr/include/QtQml \
           -I$SR/usr/include/QtQmlIntegration -I$SR/usr/include/glib-2.0 \
           -I$SR/usr/lib/glib-2.0/include"
    "$NATIVE/usr/libexec/moc" $QTINC "$PLUGIN/lunaserviceadapter.h" -o "$OUT/moc_lunaserviceadapter.cpp"
    $GXX -std=c++17 -g -fPIC -Wall -Wextra -DQT_NO_KEYWORDS $QTINC -I"$PLUGIN" -I"$HERE" \
        $SOURCES -lgtest -lQt6Qml -lQt6Core -lglib-2.0 -lpthread -o "$OUT/tst_lunaservice"
    exec env QML_IMPORT_PATH="$SR/usr/lib/qml" LD_LIBRARY_PATH="$SR/usr/lib" \
        "$SR/usr/lib/ld-linux-x86-64.so.2" "$OUT/tst_lunaservice" "$@"
fi

# The headers only: the sysroot's /usr/include itself would shadow the host's
# C library.
for d in luna-service2 pbnjson gtest; do
    ln -sfn "$SR/usr/include/$d" "$OUT/inc/$d"
done
cp "$SR/usr/include/webos_application.h" "$OUT/inc/"

MOC=${MOC:-/usr/lib/qt6/libexec/moc}
QTFLAGS=$(pkg-config --cflags Qt6Qml Qt6Core glib-2.0)
QTLIBS=$(pkg-config --libs Qt6Qml Qt6Core glib-2.0)
"$MOC" $(pkg-config --cflags-only-I Qt6Qml Qt6Core) "$PLUGIN/lunaserviceadapter.h" \
    -o "$OUT/moc_lunaserviceadapter.cpp"

case $MODE in
    asan) FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=undefined" ;;
    tsan) FLAGS="-fsanitize=thread -O1" ;;
    host|valgrind) FLAGS="" ;;
    *) echo "unknown mode $MODE" >&2; exit 1 ;;
esac

${CXX:-g++} -std=c++17 -g -fPIC -Wall -Wextra -DQT_NO_KEYWORDS $FLAGS \
    -I"$OUT/inc" -I"$PLUGIN" -I"$HERE" $QTFLAGS $SOURCES \
    "$SR/usr/lib/libgtest.a" $QTLIBS -lpthread -o "$OUT/tst_lunaservice"

case $MODE in
    valgrind)
        exec valgrind --leak-check=full --errors-for-leak-kinds=definite \
            --error-exitcode=9 "$OUT/tst_lunaservice" "$@" ;;
    tsan)
        # The reports from Qt's own threads would fail every run, so the
        # exit status is the tests'; read the reports for any frame in
        # lunaserviceadapter.cpp.
        TSAN_OPTIONS=${TSAN_OPTIONS:-exitcode=0}
        export TSAN_OPTIONS
        status=0
        for t in $("$OUT/tst_lunaservice" --gtest_list_tests | sed -n 's/^  //p'); do
            "$OUT/tst_lunaservice" --gtest_filter="LunaServiceDeferred.$t" "$@" || status=1
        done
        exit $status ;;
    *)
        exec "$OUT/tst_lunaservice" "$@" ;;
esac
