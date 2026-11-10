#!/bin/sh
# Compile LuneOS.Service's plugin with GCC and Clang for x86-64, aarch64 and
# armv7 against the recipe sysroots, with the recipe's warning flags, and
# report each build's warnings. Exits non-zero on any warning or error.
#
#   X86_WORKDIR=<tmp/work/corei7-64-webos-linux/luneos-components/<ver>> \
#   AARCH64_WORKDIR=<tmp/work/aarch64-...-webos-linux/luneos-components/<ver>> \
#   ARMV7_WORKDIR=<tmp/work/cortexa...-webos-linux-gnueabi/luneos-components/<ver>> \
#       ./check-warnings.sh
#
# Clang is the host's clang++, pointed at each sysroot's libstdc++.
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(cd "$HERE/../../modules/LuneOS/Service/plugin" && pwd)
OUT=$HERE/build/warnings
mkdir -p "$OUT"
status=0

check() {
    arch=$1; D=$2; triple=$3; gccdir=$4; shift 4; archflags="$*"
    if [ -z "$D" ] || [ ! -d "$D/recipe-sysroot" ]; then
        echo "$arch: no workdir given, skipped"; status=1; return
    fi
    SR=$D/recipe-sysroot
    gccver=$(ls "$SR/usr/lib/$gccdir" | sort -V | tail -1)
    cxxinc=$SR/usr/include/c++/$gccver
    INC="-I$SR/usr/include -I$SR/usr/include/QtCore -I$SR/usr/include/QtGui -I$SR/usr/include/QtQml \
         -I$SR/usr/include/QtQmlIntegration -I$SR/usr/include/QtQuick \
         -I$SR/usr/include/glib-2.0 -I$SR/usr/lib/glib-2.0/include"
    DEFS="-D_FORTIFY_SOURCE=2 -DQT_CORE_LIB -DQT_GUI_LIB -DQT_NO_DEBUG -DQT_NO_KEYWORDS -DQT_PLUGIN \
          -DQT_QML_LIB -DQT_QUICK_LIB -D_REENTRANT"
    COMMON="-std=gnu++17 -O2 -fPIC -fstack-protector-strong -Wall -Wextra -Wformat \
            -Wformat-security -Werror=format-security $DEFS $INC -I$SRC"
    mkdir -p "$OUT/$arch"
    for h in lunaserviceadapter db8model plugin; do
        "$D/recipe-sysroot-native/usr/libexec/moc" $INC "$SRC/$h.h" -o "$OUT/$arch/moc_$h.cpp"
    done
    for cc in gcc clang; do
        log=$OUT/$arch-$cc.log; : > "$log"
        if [ $cc = gcc ]; then
            CXX="$D/recipe-sysroot-native/usr/bin/$triple/$triple-g++ --sysroot=$SR $archflags"
        else
            CXX="clang++ --target=$triple --sysroot=$SR --gcc-install-dir=$SR/usr/lib/$gccdir/$gccver \
                 -nostdinc++ -isystem $cxxinc -isystem $cxxinc/$triple $archflags"
        fi
        for f in "$SRC"/*.cpp "$OUT/$arch"/moc_*.cpp; do
            $CXX $COMMON -c "$f" -o "$OUT/$arch/$cc-$(basename "$f" .cpp).o" >> "$log" 2>&1 \
                || echo "BUILD FAILED: $f" >> "$log"
        done
        w=$(grep -c 'warning:' "$log"); e=$(grep -c 'BUILD FAILED\|error:' "$log")
        echo "$arch $cc: $w warnings, $e errors ($log)"
        [ "$w" = 0 ] && [ "$e" = 0 ] || status=1
    done
}

check x86_64 "$X86_WORKDIR" x86_64-webos-linux x86_64-webos-linux \
    -m64 -march=nehalem -mtune=generic -mfpmath=sse -msse4.2
check aarch64 "$AARCH64_WORKDIR" aarch64-webos-linux aarch64-webos-linux \
    -mbranch-protection=standard
check armv7 "$ARMV7_WORKDIR" arm-webos-linux-gnueabi arm-webos-linux-gnueabihf \
    -mthumb -mfpu=neon -mfloat-abi=hard -mcpu=cortex-a8 -D_FILE_OFFSET_BITS=64
exit $status
