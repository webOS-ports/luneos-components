#!/bin/sh
# Run the QML tests in test/ on a development machine.
#
# Each test file states in its header what it has to be run with, and run any
# other way two of them fail for reasons that have nothing to do with the code:
# tst_text_hold and tst_shared_app_parts test the LuneOS style's press-and-hold
# and selection handles, so under Qt's default style there are none to find, and
# the preferences test reads its file with a file:// XMLHttpRequest, which Qt
# refuses by default. This sets all of it, the same for every file.
#
# Each file gets its own qmltestrunner, as luna-next-cardshell's tests/run-tests.sh
# does: the stand-ins in test/imports keep process-wide state (SettingsStub's
# profile among them), so one process can only ever be one device.
#
# The modules have to be built first (qmake6 && make at the top), since
# LuneOS.Components is partly a C++ plugin. test/device holds tests that need a
# real device and is not run here.
#
# Override MODULES or QMLTESTRUNNER if your build or Qt lives elsewhere; any
# arguments are passed on to qmltestrunner. On a machine without a display, run
# with QT_QPA_PLATFORM=offscreen.
#
# A Qt 6 qmltestrunner is looked for before the one on PATH: on Debian and
# Ubuntu that one is often qtchooser's wrapper, which runs Qt 5's.
MODULES=${MODULES:-../modules}
if [ -z "${QMLTESTRUNNER:-}" ]; then
    for candidate in /usr/lib/qt6/bin/qmltestrunner \
            $(ls -d "$HOME"/Qt/6.*/gcc_64/bin/qmltestrunner 2>/dev/null | sort -V | tail -1) \
            "$(command -v qmltestrunner)"; do
        if [ -x "$candidate" ]; then
            QMLTESTRUNNER=$candidate
            break
        fi
    done
fi

cd "$(dirname "$0")" || exit 1

if [ ! -x "$QMLTESTRUNNER" ]; then
    echo "qmltestrunner not found; set QMLTESTRUNNER to your Qt's bin/qmltestrunner" >&2
    exit 1
fi

if ! ls "$MODULES"/LuneOS/Components/libLuneOSComponents.so >/dev/null 2>&1; then
    echo "LuneOS.Components is not built in $MODULES; run qmake6 && make first, or set MODULES" >&2
    exit 1
fi

export QT_QUICK_CONTROLS_STYLE=QtQuick.Controls.LuneOS
export QML_XHR_ALLOW_FILE_READ=1

# The settings tests write a preferences file; keep them out of the real
# ~/.config and start every run from nothing.
XDG_CONFIG_HOME=$(mktemp -d) || exit 1
export XDG_CONFIG_HOME
trap 'rm -rf "$XDG_CONFIG_HOME"' EXIT

status=0
for t in tst_*.qml; do
    echo "--- $t"
    "$QMLTESTRUNNER" -input "$t" \
        -import "$MODULES" \
        -import imports "$@" || status=1
done

exit $status
