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

import QtQuick 2.9
import QtQuick.Controls 2.2

import Eos.Window 0.1
import LunaNext.Common 0.1
import LuneOS.Forms 1.0

/*
 * The window of a settings-style app with pages: the grey backdrop, the
 * AppHeader showing the current page's title and action, and a page stack
 * the back gesture pops. Messwerk and Remote each built this by hand.
 *
 *     AppWindow {
 *         title: "Remote"
 *         icon: Qt.resolvedUrl("../icon.png")
 *         initialPage: Qt.resolvedUrl("RemotesPage.qml")
 *     }
 *
 * A page sets its title, and an AppPage its headerAction. Anything declared
 * inside lands between the header and the pages (Remote's status notice);
 * give it a height and the pages start below it.
 */
WebOSWindow {
    id: appWindow

    // The first page. Converted to a string before StackView sees it: Qt 6's
    // StackView silently ignores an initialItem given as a url, which is
    // what Qt.resolvedUrl() returns (a plain string or .toString() works).
    property url initialPage
    // Shown when the current page has no title of its own
    property string defaultTitle: title
    property alias icon: header.icon
    // A Back key in the header once a page has been pushed, for an app often
    // used without the gesture area
    property bool showBack: false

    // The settings apps' header height, less of it where the screen has
    // little to spare - a phone's width, or the Q25's square
    property real headerHeight: (height < Units.gu(70) || width < Units.gu(50)) ? Units.gu(7.5)
                                                                             : Units.gu(10)

    readonly property alias pageStack: stack
    readonly property alias header: header

    default property alias content: belowHeader.data

    width: Settings.displayWidth
    height: Settings.displayHeight
    visible: true
    windowType: "_WEBOS_WINDOW_TYPE_CARD"

    Rectangle {
        z: -1
        anchors.fill: parent
        color: Colors.pageBackground
    }

    AppHeader {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: appWindow.headerHeight

        title: stack.currentItem && stack.currentItem.title ? stack.currentItem.title : appWindow.defaultTitle
        compact: width < Units.gu(50)
        showBack: appWindow.showBack && stack.depth > 1
        actionComponent: stack.currentItem && stack.currentItem.headerAction !== undefined
                         ? stack.currentItem.headerAction : null

        onBackClicked: stack.pop()
    }

    Column {
        id: belowHeader

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }

    StackView {
        id: stack

        anchors.top: belowHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        focus: true

        Component.onCompleted: {
            if (appWindow.initialPage.toString() !== "")
                push(appWindow.initialPage.toString());
        }

        // The back gesture arrives as Escape (see LunaNext.Common's EventType)
        Keys.onReleased: function(event) {
            if (event.key === Qt.Key_Escape && stack.depth > 1) {
                stack.pop();
                event.accepted = true;
            }
        }
    }
}
