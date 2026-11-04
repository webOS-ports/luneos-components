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
import QtQuick.Controls
import QtTest

/*
 * The LuneOS style's plain Popup and the on-screen keyboard: centred on the
 * window with none up, centred above the keys with one up, its top kept on
 * screen when it is taller than what the keys leave, and a popup that
 * places itself left where it put itself. Run with test/run-tests.sh (the
 * LuneOS style).
 */
Item {
    id: window
    width: 480
    height: 800

    Popup {
        id: popup
        width: 300
        height: 250
    }

    Popup {
        id: tall
        width: 300
        height: 600
    }

    Popup {
        id: placed
        width: 300
        height: 250
        y: 10
    }

    TestCase {
        name: "PopupKeyboard"
        when: windowShown

        function cleanup() {
            [popup, tall, placed].forEach(function(p) {
                p._keyboard.heightForTest = -1;
                p.close();
            });
        }

        function test_centred_without_keyboard() {
            popup._keyboard.heightForTest = 0;
            popup.open();
            compare(popup.keyboardTop, popup.parent.height);
            compare(popup.x, (popup.parent.width - 300) / 2);
            compare(popup.y, (popup.parent.height - 250) / 2);
        }

        function test_above_keyboard() {
            var kb = 360;   // the lower 45% of 800
            popup._keyboard.heightForTest = kb;
            popup.open();
            var top = popup.parent.height - kb;
            compare(popup.keyboardTop, top);
            compare(popup.y, (top - 250) / 2);
            verify(popup.y + popup.height <= top, "the popup ends above the keys");
            // The keyboard going puts it back in the middle.
            popup._keyboard.heightForTest = 0;
            compare(popup.y, (popup.parent.height - 250) / 2);
        }

        function test_taller_than_the_room_keeps_its_top() {
            tall._keyboard.heightForTest = 360;
            tall.open();
            compare(tall.y, 0);
        }

        function test_own_position_is_kept() {
            placed._keyboard.heightForTest = 360;
            placed.open();
            compare(placed.y, 10);
        }
    }
}
