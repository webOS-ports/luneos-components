#!/bin/sh
# Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 3.
#
# static-analysis.sh - static-analysis gate for LuneOS.Camera's C++.
#
#   gcc -fanalyzer    use after free, double free, leaks, NULL dereference,
#                     uninitialised reads; at -O0 and -O2
#   clang analyzer    the same from a second engine, with the alpha
#                     checkers for unix, security and core
#   clang-tidy        clang-analyzer-*, bugprone-*, cert-*, concurrency-*,
#                     performance-*
#   cppcheck          all checks, exhaustive, inconclusive included
#   flawfinder        race-prone and unsafe calls, level 1 and up
#
# sparse is not run: it parses C only. Coccinelle is not run either: its C++
# support does not get through Qt's headers.
#
# Needs a sysroot with Qt 6, GStreamer (with gstreamer-photography) and zbar:
#   CAMERA_SYSROOT=<.../recipe-sysroot> ./static-analysis.sh
# Findings are reported for this module's own files only. A tool that is not
# installed is reported and skipped, not passed.
set -u

DIR=$(cd "$(dirname "$0")/.." && pwd)
SYSROOT=${CAMERA_SYSROOT:?set CAMERA_SYSROOT to a recipe-sysroot}
U=$SYSROOT/usr/include
CXXV=$(ls "$U/c++" | head -1)
TRIPLE=$(ls "$U/c++/$CXXV" | grep -- -linux | head -1)
MOC=${CAMERA_MOC_DIR:-}

FLAGS="-std=c++17 -fPIC -DQT_NO_DEBUG -DGST_USE_UNSTABLE_API -DHAVE_QGSTREAMER_VIDEO_SOURCE
 -nostdinc++ -isystem $U/c++/$CXXV -isystem $U/c++/$CXXV/$TRIPLE --sysroot=$SYSROOT
 -isystem $U -isystem $U/gstreamer-1.0 -isystem $U/glib-2.0 -isystem $SYSROOT/usr/lib/glib-2.0/include
 -isystem $U/QtCore -isystem $U/QtGui -isystem $U/QtQml -isystem $U/QtQuick -isystem $U/QtMultimedia
 -isystem $U/QtQmlIntegration -isystem $U/QtNetwork -isystem $U/QtMultimedia/$(ls $U/QtMultimedia | grep '^6' | head -1)
 -I$DIR ${MOC:+-I$MOC}"
SOURCES="cameracontrols.cpp barcodedecoder.cpp barcodescanner.cpp droidcamerabin.cpp
 droidcamerafactory.cpp camerasensorinfo.cpp plugin.cpp"
OURS='(cameracontrols|barcodedecoder|barcodescanner|droidcamerabin|droidcamerafactory|camerasensorinfo|camerageometry|plugin)[.](cpp|h)'
fail=0

report() {
	name=$1; out=$2
	hits=$(printf '%s\n' "$out" | grep -E "$OURS" | grep -Ei 'warning|error|style|portability|performance|hit' || true)
	if [ -n "$hits" ]; then
		echo "== $name: FINDINGS"; printf '%s\n' "$hits"; fail=1
	else
		echo "== $name: clean"
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
		$SOURCES -- $FLAGS 2>&1)
	report clang-tidy "$out"
fi
if have cppcheck; then
	out=$(cppcheck --enable=all --check-level=exhaustive --inconclusive --std=c++17 --quiet \
		--suppress=missingIncludeSystem --suppress=unusedFunction --suppress=checkersReport \
		-DQ_OBJECT= -DQ_SIGNALS=public -Dsignals=public -DQ_SLOTS= -Dslots= -DQ_INVOKABLE= -DQ_ENUM\(x\)= \
		-DQ_PROPERTY\(x\)= -Demit= -DG_DEFINE_TYPE\(a,b,c\)= \
		-DQ_LOGGING_CATEGORY\(...\)= -DHAVE_QGSTREAMER_VIDEO_SOURCE $SOURCES 2>&1)
	report cppcheck "$out"
fi
if have flawfinder; then
	out=$(flawfinder --minlevel=1 --columns --quiet --dataonly $SOURCES *.h 2>&1)
	report flawfinder "$out"
fi
exit $fail
