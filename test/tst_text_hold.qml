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
 * Holding a finger on text in the style's TextField and TextArea selects the
 * word under it and brings up the selection handles; taps, drags and flicks
 * do what they did:
 *   QT_QUICK_CONTROLS_STYLE=QtQuick.Controls.LuneOS \
 *   qmltestrunner -import modules -import test/imports -input test/tst_text_hold.qml
 */
Item {
    id: root
    width: 480
    height: 800

    TextField {
        id: field
        x: 20; y: 20; width: 440
        text: "The quick brown fox jumps"
    }

    TextField {
        id: readOnlyField
        x: 20; y: 100; width: 440
        readOnly: true
        text: "Read only words here"
    }

    ScrollView {
        id: scroller
        x: 20; y: 200; width: 440; height: 200
        TextArea {
            id: area
            wrapMode: TextEdit.Wrap
            text: {
                var lines = [];
                for (var i = 0; i < 40; i++)
                    lines.push("Line number " + i + " of the long text");
                return lines.join("\n");
            }
        }
    }

    TestCase {
        name: "TextHold"
        when: windowShown

        readonly property int hold: Qt.styleHints.mousePressAndHoldInterval + 200

        // The middle of the character at position, in the control's coordinates.
        function pointAt(control, position) {
            var r = control.positionToRectangle(position);
            var next = control.positionToRectangle(position + 1);
            var dx = control.lineCount === undefined ? control.leftPadding : 0;
            var dy = control.lineCount === undefined ? control.topPadding : 0;
            return Qt.point((r.x + next.x) / 2 + dx, r.y + r.height / 2 + dy);
        }

        function handlesOf(control) {
            for (var i = 0; i < control.children.length; ++i)
                if (control.children[i].shown !== undefined)
                    return control.children[i];
            return null;
        }

        function init() {
            field.deselect();
            area.deselect();
            readOnlyField.deselect();
            root.forceActiveFocus();
        }

        function test_mouse_hold_selects_the_word() {
            var p = pointAt(field, 12);  // the "o" of "brown"
            mousePress(field, p.x, p.y);
            wait(hold);
            mouseRelease(field, p.x, p.y);
            compare(field.selectedText, "brown");
            verify(field.activeFocus);
            verify(handlesOf(field).shown, "the handles come up");
        }

        function test_touch_hold_selects_the_word() {
            var p = pointAt(field, 6);  // in "quick"
            var t = touchEvent(field);
            t.press(0, field, p.x, p.y).commit();
            wait(hold);
            t.release(0, field, p.x, p.y).commit();
            compare(field.selectedText, "quick");
            verify(handlesOf(field).shown);
        }

        function test_tap_places_the_cursor() {
            var p = pointAt(field, 12);
            mouseClick(field, p.x, p.y);
            compare(field.selectedText, "");
            verify(field.cursorPosition === 12 || field.cursorPosition === 13, "cursor at the tap: " + field.cursorPosition);
            verify(!handlesOf(field).shown);
        }

        function test_hold_on_a_space_selects_nothing() {
            var p = pointAt(field, 9);  // the space after "quick"
            mousePress(field, p.x, p.y);
            wait(hold);
            mouseRelease(field, p.x, p.y);
            compare(field.selectedText, "");
            verify(!handlesOf(field).shown);
        }

        function test_quick_drag_is_not_a_hold() {
            var p = pointAt(field, 12);
            var q = pointAt(field, 18);
            mousePress(field, p.x, p.y);
            mouseMove(field, (p.x + q.x) / 2, p.y);
            mouseMove(field, q.x, q.y);
            mouseRelease(field, q.x, q.y);
            verify(field.selectionStart !== 10, "no whole-word selection from a drag: " + field.selectionStart);
        }

        // A finger moving for longer than a hold is a drag, never a hold.
        function test_moving_finger_is_not_a_hold() {
            var p = pointAt(field, 2);
            var t = touchEvent(field);
            t.press(0, field, p.x, p.y).commit();
            var steps = Math.ceil(hold / 20);
            for (var i = 1; i <= steps; i++) {
                t.move(0, field, p.x + i * 200 / steps, p.y).commit();
                wait(20);
            }
            t.release(0, field, p.x + 200, p.y).commit();
            verify(field.selectedText !== "The", "no word selected: " + field.selectedText);
        }

        // Inside a ScrollView the moves go to the Flickable and Qt's hold
        // timer can fire while the text scrolls under the finger: that is a
        // flick, and selects nothing. (Here the area is scrolled by hand while
        // the finger is down: with synthesized touch the ScrollView takes no
        // flick, with Qt's own Basic style either, so the flick itself is
        // checked on the devices.)
        function test_text_scrolled_under_the_finger_is_not_a_hold() {
            scroller.contentItem.contentY = 0;
            var p = pointAt(area, 3);
            mousePress(area, p.x, p.y);
            wait(100);
            scroller.contentItem.contentY = 120;
            wait(hold);
            mouseRelease(area, p.x, p.y);
            compare(area.selectedText, "");
            verify(!handlesOf(area).shown);
            scroller.contentItem.contentY = 0;
        }

        function test_hold_in_the_area_selects_the_word() {
            scroller.contentItem.contentY = 0;
            var p = pointAt(area, 3);  // in "Line"
            mousePress(area, p.x, p.y);
            wait(hold);
            mouseRelease(area, p.x, p.y);
            compare(area.selectedText, "Line");
            verify(handlesOf(area).shown);
        }

        function test_hold_in_a_read_only_field() {
            var p = pointAt(readOnlyField, 6);  // in "only"
            mousePress(readOnlyField, p.x, p.y);
            wait(hold);
            mouseRelease(readOnlyField, p.x, p.y);
            compare(readOnlyField.selectedText, "only", "selected, to copy");
        }
    }
}
