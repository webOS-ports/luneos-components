#!/bin/sh
# Static analysis of lunaserviceadapter.cpp against the x86-64 recipe sysroot:
# gcc -fanalyzer at -O0 and -O2, clang --analyze with the alpha checkers,
# clang-tidy, cppcheck and flawfinder. Each tool's output goes to
# build/analysis/<tool>.log; the counts printed are for triage, not a verdict.
#
#   X86_WORKDIR=<tmp/work/corei7-64-webos-linux/luneos-components/<ver>> ./static-analysis.sh
#
# Known noise, as of Qt 6.12 and GCC 15: -fanalyzer's "use of uninitialized
# value" inside QArrayDataPointer::allocateGrow (once per QList element type),
# and clang's alpha IteratorRange in qlist.h's indexOf; clang-tidy's
# performance-unnecessary-value-param on the QJSValue parameters of the API.
if [ -z "$X86_WORKDIR" ] || [ ! -d "$X86_WORKDIR/recipe-sysroot" ]; then
    echo "set X86_WORKDIR to the corei7-64 workdir of the luneos-components recipe" >&2
    exit 1
fi
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(cd "$HERE/../../modules/LuneOS/Service/plugin" && pwd)
OUT=$HERE/build/analysis
mkdir -p "$OUT"
D=$X86_WORKDIR; SR=$D/recipe-sysroot
gccver=$(ls "$SR/usr/lib/x86_64-webos-linux" | sort -V | tail -1)
cxxinc=$SR/usr/include/c++/$gccver
GXX="$D/recipe-sysroot-native/usr/bin/x86_64-webos-linux/x86_64-webos-linux-g++ --sysroot=$SR"
CLANGSYS="--target=x86_64-webos-linux --sysroot=$SR --gcc-install-dir=$SR/usr/lib/x86_64-webos-linux/$gccver \
          -nostdinc++ -isystem $cxxinc -isystem $cxxinc/x86_64-webos-linux"
INC="-I$SR/usr/include/QtCore -I$SR/usr/include/QtQml -I$SR/usr/include/QtQmlIntegration \
     -I$SR/usr/include/glib-2.0 -I$SR/usr/lib/glib-2.0/include -I$SR/usr/include"
DEFS="-DQT_CORE_LIB -DQT_QML_LIB -DQT_NO_KEYWORDS -DQT_NO_DEBUG -D_REENTRANT"
F=$SRC/lunaserviceadapter.cpp

for o in O0 O2; do
    $GXX -std=gnu++17 -$o -fanalyzer $DEFS $INC -I"$SRC" -c "$F" -o /dev/null > "$OUT/fanalyzer-$o.log" 2>&1
done
clang++ $CLANGSYS --analyze --analyzer-output text -std=gnu++17 $DEFS $INC -I"$SRC" \
    -Xclang -analyzer-checker=core,cplusplus,unix,security,deadcode,alpha.core,alpha.unix,alpha.security,alpha.cplusplus \
    -Xclang -analyzer-config -Xclang aggressive-binary-operation-simplification=true \
    -o /dev/null "$F" > "$OUT/clang-analyze.log" 2>&1
clang-tidy "$F" --checks='-*,clang-analyzer-*,bugprone-*,cert-*,performance-*,-bugprone-easily-swappable-parameters' \
    -- $CLANGSYS -std=gnu++17 $DEFS $INC -I"$SRC" > "$OUT/clang-tidy.log" 2>&1
cppcheck --enable=all --check-level=exhaustive --inconclusive --std=c++17 --library=qt \
    --suppress=missingIncludeSystem --suppress=missingInclude --suppress=unusedFunction \
    -I"$SRC" $DEFS "$F" > "$OUT/cppcheck.log" 2>&1
flawfinder --minlevel=1 "$F" "$SRC/lunaserviceadapter.h" > "$OUT/flawfinder.log" 2>&1

for l in "$OUT"/*.log; do
    case $l in
        */flawfinder.log) n=$(grep -cE '^[^ ]+:[0-9]+: +\[[0-9]\]' "$l") ;;
        *) n=$(grep -cE 'warning:|error:|style:|portability:|performance:' "$l") ;;
    esac
    printf '%-16s %s findings\n' "$(basename "$l" .log)" "$n"
done
