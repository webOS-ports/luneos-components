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
import QtQuick.Controls.LuneOS 2.0
import QtTest
import LunaNext.Common 0.1

/*
 * The app menu laid out as webOS 3.0's enyo.AppMenu in the Onyx theme, in its
 * CSS pixels (ten to a grid unit): rows 10px above and below a 22px caption
 * line, a 1px gap over all but the first, a 2px divider under all but the
 * last, captions 8px into the row, the frame from 10px left of the menu,
 * the check of a check item at the end of the row without making it taller,
 * a disabled row at half opacity. An ordinary menu keeps its own look.
 *   QT_QUICK_CONTROLS_STYLE=QtQuick.Controls.LuneOS \
 *   qmltestrunner -import modules -import test/imports -input test/tst_app_menu.qml
 */
Item {
    id: page
    width: 480
    height: 800

    readonly property real px: Units.gridUnit / 10

    Menu {
        id: appMenu
        LuneOSMenu.appMenuStyle: true
        MenuItem { text: "New Album" }
        MenuItem { text: "Sync Now" }
        MenuItem { text: "Keep on Device"; checkable: true; checked: true; enabled: false }
        MenuItem { text: "Preferences & Accounts" }
    }

    Menu {
        id: plainMenu
        MenuItem { text: "Cut" }
        MenuItem { text: "Copy" }
    }

    TestCase {
        name: "AppMenu"
        when: windowShown

        function cleanup() {
            appMenu.close();
            plainMenu.close();
            tryCompare(appMenu, "visible", false);
            tryCompare(plainMenu, "visible", false);
        }

        function r(v) { return Math.round(v * page.px); }

        function test_rows() {
            appMenu.popup(0, 0);
            tryCompare(appMenu, "opened", true);
            var heights = [r(10) + r(22) + r(12), r(11) + r(22) + r(12), r(11) + r(22) + r(12), r(11) + r(22) + r(10)];
            var y = 0;
            for (var i = 0; i < appMenu.count; ++i) {
                var item = appMenu.itemAt(i);
                compare(item.height, heights[i], "row " + i + " height");
                compare(item.mapToItem(appMenu.contentItem, 0, 0).y, y, "row " + i + " top");
                compare(item.contentItem.x, r(8), "row " + i + " caption inset");
                compare(item.contentItem.color, Qt.color("white"), "row " + i + " caption colour");
                y += item.height;
            }
            compare(appMenu.contentItem.y, 0);
            compare(appMenu.contentItem.x, r(1));
            compare(appMenu.height, y + r(20));
        }

        function test_frame() {
            appMenu.popup(0, 0);
            tryCompare(appMenu, "opened", true);
            var frame = appMenu.background.children.filter(function(c) { return c.visible && c.source !== undefined; })[0];
            verify(frame, "the frame image");
            compare(String(frame.source).split("/").pop(), "appmenu.png");
            compare(frame.x, -r(10));
            // The 1.5 image, scaled to fill from there to the menu's right edge
            fuzzyCompare(frame.width * frame.scale, appMenu.width + r(10), 0.01);
            fuzzyCompare(frame.height * frame.scale, appMenu.height, 0.01);
            verify(appMenu.width + r(10) >= r(210), "at least 210px wide");
        }

        function dividerOf(item) {
            return item.background.children.filter(function(c) { return c.children.length === 2; })[0];
        }

        function test_dividers() {
            appMenu.popup(0, 0);
            tryCompare(appMenu, "opened", true);
            for (var i = 0; i < appMenu.count; ++i) {
                var item = appMenu.itemAt(i);
                var divider = dividerOf(item);
                compare(divider.visible, i < appMenu.count - 1, "divider under row " + i);
                compare(divider.height, r(2));
                compare(divider.y + divider.height, item.height);
                compare(divider.x, r(3));
                compare(divider.width, item.width - 2 * r(3));
            }
        }

        function test_checkAndDisabled() {
            appMenu.popup(0, 0);
            tryCompare(appMenu, "opened", true);
            var keep = appMenu.itemAt(2);
            var plain = appMenu.itemAt(1);
            compare(keep.height, plain.height, "a check item is no taller");
            compare(keep.contentItem.x, plain.contentItem.x, "its caption is not moved over");
            compare(keep.contentItem.rightPadding, r(34));
            verify(keep.indicator.visible);
            compare(keep.indicator.width, r(32));
            compare(keep.indicator.x + keep.indicator.width, keep.width - keep.rightPadding);
            compare(keep.opacity, 0.5);
            compare(plain.opacity, 1);
        }

        function test_held() {
            appMenu.popup(0, 0);
            tryCompare(appMenu, "opened", true);
            var item = appMenu.itemAt(1);
            var highlight = item.background.children.filter(function(c) { return c.source !== undefined && String(c.source).indexOf("appmenu-highlight") >= 0; })[0];
            verify(highlight);
            verify(!highlight.visible);
            mousePress(item, item.width / 2, item.height / 2);
            verify(highlight.visible);
            compare(highlight.height, item.height);
            mouseRelease(item, item.width / 2, item.height / 2);
        }

        function test_plainMenuUnchanged() {
            plainMenu.popup(0, 0);
            tryCompare(plainMenu, "opened", true);
            compare(plainMenu.leftPadding, 20);
            compare(plainMenu.topPadding, 10);
            var item = plainMenu.itemAt(0);
            compare(item.height, 40);
            compare(item.opacity, 1);
            compare(item.contentItem.color, Qt.color("#26282a"));
            verify(!dividerOf(item).visible);
        }
    }
}
