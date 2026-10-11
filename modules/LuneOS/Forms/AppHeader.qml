/*
 * (c) 2013 Simon Busch <morphis@gravedo.de>
 * (c) 2017 Christophe Chapuis <chris.chapuis@gmail.com>
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

// Theme specific properties
import QtQuick.Controls.LuneOS 2.0
// Units & font sizes
import LunaNext.Common 0.1

/*
 * The light toolbar at the top of a settings-style app: the app's icon, its
 * bold title and the current page's action on the right. Settings'
 * CategoryHeader, with Messwerk's additions - a title that elides before it
 * reaches the action, and a smaller title for a narrow window.
 *
 * Going back is normally left to the back gesture. "showBack" puts a Back
 * key in front as well, for an app that is often driven without the gesture
 * area (Remote, on a tablet in a stand); it emits backClicked().
 */
Pane {
    id: root

    property string title
    // Pass it through Qt.resolvedUrl(): Qt 6 no longer resolves a relative
    // url where it is assigned, so a bare "images/icon.png" would be looked
    // for next to this file instead of the app's.
    property url icon
    property alias actionComponent: actionLoader.sourceComponent
    // A smaller title, for a header that has little room - set it from the
    // window, e.g. "compact: width < Units.gu(50)".
    property bool compact: false
    property bool showBack: false

    signal backClicked()

    padding: 0

    background: Image {
        source: "images/toolbar-light.png"
        fillMode: Image.Stretch
    }

    Button {
        id: backButton

        anchors.left: parent.left
        anchors.leftMargin: visible ? Units.gu(1) : 0
        anchors.verticalCenter: parent.verticalCenter
        width: visible ? implicitWidth : 0

        visible: root.showBack
        text: "Back"
        LuneOSButton.mainColor: LuneOSButton.secondaryColor

        onClicked: root.backClicked()
    }

    Image {
        id: iconImage

        anchors.left: backButton.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Units.gu(1)
        width: visible ? height : 0
        // In a compact header the icon gives way to the Back key: the title
        // is what says where you are
        visible: root.icon.toString() !== "" && !(root.compact && root.showBack)

        source: root.icon
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    Label {
        // Bounded on both sides, so a long title elides before it reaches
        // the page's action instead of running underneath it
        anchors.left: iconImage.right
        anchors.leftMargin: Units.gu(1)
        anchors.right: actionLoader.left
        anchors.rightMargin: Units.gu(1)
        anchors.verticalCenter: parent.verticalCenter

        text: root.title
        elide: Text.ElideRight
        font.pixelSize: FontUtils.sizeToPixels(root.compact ? "medium" : "large")
        font.weight: Font.Bold
    }

    Loader {
        id: actionLoader

        anchors.right: parent.right
        anchors.rightMargin: Units.gu(1.5)
        anchors.verticalCenter: parent.verticalCenter
    }
}
