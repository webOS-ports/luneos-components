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
import LuneOS.Forms 1.0

/*
 * AppWindow opens on its initialPage, already in place when the window is
 * created, and on an empty stack without one:
 *   qmltestrunner -import modules -import test/imports -input test/tst_appwindow.qml
 */
TestCase {
    name: "AppWindow"

    Component {
        id: withPage
        AppWindow {
            title: "App"
            initialPage: Qt.resolvedUrl("appwindow/FirstPage.qml")
        }
    }

    Component {
        id: withoutPage
        AppWindow {
            title: "App"
        }
    }

    function test_opens_on_the_initial_page() {
        failOnWarning(/StackView/);
        var win = createTemporaryObject(withPage, this);
        compare(win.pageStack.depth, 1);
        compare(win.pageStack.currentItem.title, "First");
        compare(win.header.title, "First");
        verify(!win.pageStack.busy, "the first page slid in");
    }

    function test_no_initial_page_is_an_empty_stack() {
        failOnWarning(/StackView/);
        var win = createTemporaryObject(withoutPage, this);
        compare(win.pageStack.depth, 0);
        compare(win.header.title, "App");
    }
}
