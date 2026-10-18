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
 * ActionSheet (choices, actions, headings, greyed-out and destructive rows,
 * back(), placement), FastScroller (jumping to a letter, hiding on short
 * lists) and ConfirmDialog's button words:
 *   qmltestrunner -import modules -import test/imports -input test/tst_action_sheet.qml
 */
Item {
    id: page
    width: 480
    height: 800

    property var ran: []

    ActionSheet {
        id: sheet
        anchors.fill: parent
    }

    SignalSpy {
        id: chosenSpy
        target: sheet
        signalName: "chosen"
    }

    ListView {
        id: list
        width: 300
        height: 400
        clip: true
        model: 200
        delegate: Item { width: 300; height: 40 }
    }

    FastScroller {
        id: scroller
        anchors.right: list.right
        anchors.top: list.top
        anchors.bottom: list.bottom
        view: list
    }

    ConfirmDialog {
        id: confirm
        anchors.fill: parent
        visible: false
    }

    TestCase {
        name: "ActionSheet"
        when: windowShown

        function init() {
            sheet.hide();
            tryCompare(sheet, "visible", false);
            chosenSpy.clear();
            page.ran = [];
        }

        function choices() {
            return [
                { label: "Play Next", key: "next", action: function() { page.ran = page.ran.concat(["next"]); } },
                { label: "Speed", header: true },
                { label: "Normal", key: 1, checked: true },
                { label: "Unavailable", key: "x", enabled: false, action: function() { page.ran = page.ran.concat(["x"]); } },
                { label: "Delete", key: "del", destructive: true }
            ];
        }

        function row(index) {
            return findChild(sheet, "choice_" + index);
        }

        function test_show_and_choose() {
            sheet.show("Song", choices(), "Artist");
            verify(sheet.shown);
            tryCompare(sheet, "visible", true);
            compare(findChild(sheet, "sheetTitle").text, "Song");
            compare(findChild(sheet, "sheetSubtitle").text, "Artist");
            waitForRendering(sheet);
            wait(250);
            mouseClick(row(0));
            compare(page.ran, ["next"]);
            compare(chosenSpy.count, 1);
            compare(chosenSpy.signalArguments[0][0].key, "next");
            verify(!sheet.shown);
        }

        function test_heading_and_disabled_do_nothing() {
            sheet.show("Song", choices());
            wait(250);
            sheet.choose(1);
            sheet.choose(3);
            compare(chosenSpy.count, 0);
            compare(page.ran, []);
            verify(sheet.shown);
            verify(!row(1).enabled);
            verify(!row(3).enabled);
        }

        function test_checked_and_destructive_rows() {
            sheet.show("Song", choices());
            wait(250);
            var label4 = findChild(row(4), "choiceLabel");
            verify(Qt.colorEqual(label4.color, "#ff6b5e"));
            var label2 = findChild(row(2), "choiceLabel");
            verify(Qt.colorEqual(label2.color, "white"));
            // Only the checked row has its tick.
            verify(findChild(row(2), "choiceTick").visible);
            verify(!findChild(row(4), "choiceTick").visible);
        }

        function test_plain_text_field_is_accepted() {
            sheet.show("", [{ text: "Old style" }]);
            wait(250);
            compare(findChild(row(0), "choiceLabel").text, "Old style");
        }

        function test_tap_outside_closes() {
            sheet.show("Song", choices());
            wait(250);
            mouseClick(sheet, 10, 10);
            verify(!sheet.shown);
            compare(chosenSpy.count, 0);
        }

        function test_back() {
            verify(!sheet.back());
            sheet.show("Song", choices());
            verify(sheet.back());
            verify(!sheet.shown);
        }

        function test_placement() {
            verify(!sheet.centered);
            sheet.placement = "center";
            verify(sheet.centered);
            sheet.placement = "auto";
            page.width = 1024;
            verify(sheet.centered);
            page.width = 480;
        }
    }

    TestCase {
        name: "FastScroller"
        when: windowShown

        function test_hidden_for_short_lists() {
            scroller.sections = ["A", "B", "C"];
            verify(!scroller.visible);
        }

        function test_jumps_to_letter() {
            var s = [];
            for (var i = 0; i < 200; i++)
                s.push(i < 100 ? "A" : (i < 150 ? "M" : "Z"));
            scroller.sections = s;
            verify(scroller.visible);
            list.positionViewAtBeginning();
            var touch = findChild(scroller, "fastScrollerTouch");
            // Three letters: the bottom third is Z.
            mousePress(touch, touch.width / 2, touch.height - 5);
            mouseRelease(touch, touch.width / 2, touch.height - 5);
            compare(list.indexAt(10, list.contentY + 1), 150);
            mousePress(touch, touch.width / 2, touch.height / 2);
            mouseRelease(touch, touch.width / 2, touch.height / 2);
            compare(list.indexAt(10, list.contentY + 1), 100);
        }
    }

    TestCase {
        name: "ConfirmDialog"
        when: windowShown

        function test_default_words() {
            compare(findChild(confirm, "confirmAcceptButton").text, "OK");
            compare(findChild(confirm, "confirmRejectButton").text, "Cancel");
        }

        function test_own_words_and_red() {
            confirm.acceptText = "Delete";
            confirm.destructive = true;
            var accept = findChild(confirm, "confirmAcceptButton");
            compare(accept.text, "Delete");
            verify(Qt.colorEqual(accept.color, "#be0003"));
        }
    }
}
