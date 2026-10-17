/*
 * (c) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import QtTest
import LunaNext.Common 0.1
import LuneOS.Components 1.0

/*
 * Dialogs and the on-screen keyboard: a Dialog left as it was, one kept clear
 * of the keyboard (and its compact height), DialogLineInput's uncommitted
 * text, and AuthenticationDialog's box above the keys:
 *   qmltestrunner -import modules -import test/imports -input test/tst_dialog_keyboard.qml
 */
Item {
    id: page
    width: 480
    height: 800

    Dialog {
        id: plain
        visible: false
        title: "Plain"
        dialogHeight: Units.gu(20)
        dialogWidth: Units.gu(30)
    }

    Dialog {
        id: clear
        visible: false
        title: "Clear"
        message: "A message"
        keepClearOfKeyboard: true
        dialogHeight: 300
        compactDialogHeight: 200
        dialogWidth: Units.gu(30)
        // In a Row, as PromptDialog has it: the line centres itself in its row
        Row {
            DialogLineInput {
                id: line
            }
        }
    }

    AuthenticationDialog {
        id: auth
        visible: false
    }

    KeyboardInset {
        id: inset
        item: page
    }

    TestCase {
        name: "DialogKeyboard"
        when: windowShown

        function boxOf(dialog) {
            // The frame: the dialog's child that is as tall as dialogHeight says
            for (var i = 0; i < dialog.children.length; ++i) {
                var c = dialog.children[i];
                if (c.radius === 10)
                    return c;
            }
            return null;
        }

        function cleanup() {
            clear.keyboardHeightForTest = -1;
            clear.visible = false;
            plain.visible = false;
            inset.heightForTest = -1;
        }

        function test_plain_dialog_unchanged() {
            plain.keyboardHeightForTest = 400;
            plain.visible = true;
            compare(plain.width, page.width);
            compare(plain.height, page.height, "covers the page, keyboard or not");
            compare(plain.keyboardHeight, 0);
            verify(!plain.compact);
            var box = boxOf(plain);
            compare(box.height, Units.gu(20));
            compare(box.y, (page.height - box.height) / 2);
            plain.keyboardHeightForTest = -1;
        }

        function test_clear_without_keyboard_is_the_whole_page() {
            clear.keyboardHeightForTest = 0;
            clear.open();
            compare(clear.height, page.height);
            verify(!clear.compact);
            compare(boxOf(clear).height, 300);
        }

        function test_clear_above_keyboard() {
            clear.keyboardHeightForTest = 350;
            clear.open();
            compare(clear.height, page.height - 350);
            verify(!clear.compact, "450 left is room for 300");
            var box = boxOf(clear);
            compare(box.height, 300);
            compare(box.y, (clear.height - 300) / 2);
            verify(box.y + box.height <= page.height - 350, "box above the keys");
        }

        function test_clear_compact_when_keyboard_leaves_too_little() {
            clear.keyboardHeightForTest = 560;
            clear.open();
            verify(clear.compact);
            var box = boxOf(clear);
            compare(box.height, 200);
            compare(clear.height, page.height - 560);
            verify(box.y >= 0 && box.y + box.height <= page.height - 560);
        }

        function test_clear_never_shorter_than_its_box() {
            clear.keyboardHeightForTest = 700;
            clear.open();
            compare(clear.height, 200, "the box stays whole, the dialog grows over the keys");
            clear.compactDialogHeight = -1;
            verify(clear.compact);
            compare(boxOf(clear).height, 300, "no compact height: dialogHeight still");
            compare(clear.height, 300);
            clear.compactDialogHeight = 200;
        }

        function test_open_close() {
            var shown = 0, closed = 0;
            var onShow = function() { ++shown; };
            var onClose = function() { ++closed; };
            clear.aboutToShow.connect(onShow);
            clear.closed.connect(onClose);
            clear.open();
            verify(clear.opened);
            clear.close();
            verify(!clear.opened);
            compare(shown, 1);
            compare(closed, 1);
            clear.aboutToShow.disconnect(onShow);
            clear.closed.disconnect(onClose);
        }

        function test_line_typed_text_includes_preedit() {
            line.text = "secre";
            line.textInput.cursorPosition = 5;
            compare(line.typedText(), "secre", "nothing uncommitted");
            line.inputMethodHints = Qt.ImhDigitsOnly;
            compare(line.textInput.inputMethodHints, Qt.ImhDigitsOnly);
            line.passwordCharacter = "•";
            compare(line.textInput.passwordCharacter, "•");
            verify(line.textInput.leftPadding > 0);
        }

        function test_auth_dialog_above_keyboard() {
            auth.visible = true;
            var box = null;
            for (var i = 0; i < auth.children.length; ++i)
                if (auth.children[i].radius === 10)
                    box = auth.children[i];
            verify(box);
            // No keyboard: centred in the page
            fuzzyCompare(box.y, (page.height - box.height) / 2, 1);
            // A keyboard over the lower 400: centred in the 400 above it
            auth.keyboardHeightForTest = 400;
            fuzzyCompare(box.y, (400 - box.height) / 2, 1);
            verify(box.y + box.height <= 400, "clear of the keys");
            // One that leaves less room than the box: kept on screen at the top
            auth.keyboardHeightForTest = 700;
            compare(box.y, Units.gu(1));
            auth.keyboardHeightForTest = -1;
            auth.visible = false;
        }

        function test_inset() {
            compare(inset.top, page.height, "no keyboard on the test host");
            compare(inset.height, 0);
            inset.heightForTest = 300;
            compare(inset.top, 500);
            compare(inset.height, 300);
            inset.heightForTest = 2000;
            compare(inset.top, 0);
            compare(inset.height, page.height);
        }
    }
}
