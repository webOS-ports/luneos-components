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

import QtQuick 2.12
import QtQuick.Controls 2.0
import LunaNext.Common 0.1

/*
 * A short word on top of the app for a moment - "Wallpaper set", "Copied" -
 * as webOS's banners said it inside the card. show() puts it up for
 * duration milliseconds, fading in and out over fadeDuration; place it where
 * it should be (centred by default). It is a Rectangle: radius and color
 * give it another shape, a pill say.
 *
 *   Toast { id: toast }   ...   toast.show("Wallpaper set")
 *   Toast { radius: height / 2; color: "#d0202020" }
 */
Rectangle {
    id: toast

    property alias text: label.text
    property int duration: 2500
    // How long it takes to come and to go; 0 for at once
    property int fadeDuration: 250
    readonly property bool showing: timer.running

    function show(newText) {
        label.text = newText;
        timer.restart();
    }

    anchors.centerIn: parent
    width: Math.min(label.implicitWidth, parent ? parent.width - Units.gu(8) : label.implicitWidth) + Units.gu(4)
    height: label.height + Units.gu(2)
    radius: Units.gu(1)
    color: "#d0000000"
    // Shown from the moment it is asked for, and until it has faded out
    visible: timer.running || opacity > 0
    opacity: timer.running ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: toast.fadeDuration }
    }
    z: 100

    Label {
        id: label
        objectName: "toast"
        anchors.centerIn: parent
        width: parent.width - Units.gu(4)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: "white"
        font.pixelSize: FontUtils.sizeToPixels("medium")
    }

    Timer {
        id: timer
        interval: toast.duration
    }
}
