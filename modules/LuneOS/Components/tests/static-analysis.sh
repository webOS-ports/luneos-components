#!/bin/sh
# Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 3.
#
# static-analysis.sh - static-analysis gate for LuneOS.Components' C++
# (plugin/artworkcache.cpp):
#
#   gcc -fanalyzer    at -O0 and -O2
#   clang analyzer    with the alpha checkers for unix, security and core
#   clang-tidy        clang-analyzer-*, bugprone-*, cert-*, concurrency-*,
#                     performance-*
#   cppcheck          all checks, exhaustive, inconclusive included
#   flawfinder        level 1 and up
#
# sparse parses C only and Coccinelle does not get through Qt's headers, so
# neither is run.
#
# Needs a sysroot with Qt 6 (Core, Gui, Svg) headers:
#   APP_SYSROOT=<.../recipe-sysroot> ./static-analysis.sh
set -u

DIR=$(cd "$(dirname "$0")/../plugin" && pwd)
SYSROOT=${APP_SYSROOT:?set APP_SYSROOT to a recipe-sysroot}
U=$SYSROOT/usr/include
CXXV=$(ls "$U/c++" | head -1)
TRIPLE=$(ls "$U/c++/$CXXV" | grep -- -linux | head -1)

FLAGS="-std=c++17 -fPIC -nostdinc++ -isystem $U/c++/$CXXV -isystem $U/c++/$CXXV/$TRIPLE --sysroot=$SYSROOT
 -isystem $U -isystem $U/QtCore -isystem $U/QtGui -isystem $U/QtSvg -I$DIR"
SOURCES="artworkcache.cpp"
OURS='artworkcache[.](cpp|h)'
fail=0

report() {
	hits=$(printf '%s\n' "$2" | grep -E "$OURS" | grep -Ei 'warning|error|style|portability|performance|hit' || true)
	if [ -n "$hits" ]; then
		echo "== $1: FINDINGS"; printf '%s\n' "$hits"; fail=1
	else
		echo "== $1: clean"
	fi
}
have() { command -v "$1" >/dev/null 2>&1 || { echo "== $1: not installed, skipped"; return 1; }; }

cd "$DIR"
if have g++; then
	for opt in -O0 -O2; do
		out=""
		for f in $SOURCES; do
			out="$out$(g++ $opt -fanalyzer -fsyntax-only -Wall -Wextra $FLAGS "$f" 2>&1)
"
		done
		report "gcc -fanalyzer $opt" "$out"
	done
fi
if have clang++; then
	out=""
	for f in $SOURCES; do
		out="$out$(clang++ --analyze -Xclang -analyzer-checker=core,unix,security,alpha.core,alpha.unix,alpha.security,cplusplus \
			$FLAGS "$f" -o /dev/null 2>&1)
"
	done
	report "clang --analyze" "$out"
fi
if have clang-tidy; then
	out=$(clang-tidy -quiet --checks='-*,clang-analyzer-*,bugprone-*,cert-*,concurrency-*,performance-*,-bugprone-easily-swappable-parameters,-cert-err58-cpp' \
		$SOURCES -- $FLAGS --target=$TRIPLE 2>&1)
	report clang-tidy "$out"
fi
if have cppcheck; then
	out=$(cppcheck --enable=all --check-level=exhaustive --inconclusive --std=c++17 --quiet \
		--suppress=missingIncludeSystem --suppress=unusedFunction --suppress=checkersReport \
		-DQ_OBJECT= -DQ_SIGNALS=public -DQ_EMIT= -DQ_INVOKABLE= $SOURCES 2>&1)
	report cppcheck "$out"
fi
if have flawfinder; then
	out=$(flawfinder --minlevel=1 --columns --quiet --dataonly $SOURCES jpegexif.h imagetools.h 2>&1)
	report flawfinder "$out"
fi
exit $fail
