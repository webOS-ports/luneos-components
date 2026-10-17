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
import LunaNext.Common 0.1
import LuneOS.Components 1.0

/*
 * A toolbar key with a picture, or a short text in place of one, at least
 * 54 px across - the legacy guidelines' smallest touch target. The picture
 * is the app's own SVG, drawn sharp at its size by ArtworkImage: source is
 * its file: URL, or image names "<image>.svg" in imageFolder, which an app
 * sets once in a small wrapper of its own:
 *
 *   // qml/components/IconButton.qml
 *   Forms.IconToolButton { imageFolder: Qt.resolvedUrl("../images/") }
 *
 * How it is drawn, by appearance:
 *   "toolbar"  on the legacy dark toolbar: a darker key while held or checked
 *   "plain"    on the light header: nothing behind it but a shade while held
 *   "overlay"  over a picture or video: a light veil while held or checked
 */
ToolButton {
    id: button

    property url source: image !== "" && imageFolder.toString() !== ""
                         ? imageFolder.toString() + image + ".svg" : ""
    property url imageFolder
    property string image
    // Shown when there is no picture.
    property string label
    property color labelColor: "white"
    property string appearance: "toolbar"
    // The picture's share of the button.
    property real iconSize: Units.gu(3)

    implicitWidth: Math.max(Units.gu(6), 54)
    implicitHeight: Math.max(Units.gu(5), 54)
    padding: 0
    focusPolicy: Qt.NoFocus

    contentItem: Item {
        ArtworkImage {
            objectName: "iconButtonImage"
            anchors.centerIn: parent
            width: button.iconSize
            height: button.iconSize
            visible: button.source.toString() !== ""
            svg: button.source
            opacity: button.enabled ? 1.0 : 0.35
        }
        Text {
            anchors.centerIn: parent
            visible: button.source.toString() === ""
            text: button.label
            color: button.labelColor
            opacity: button.enabled ? 1.0 : 0.35
            font.pixelSize: FontUtils.sizeToPixels("medium")
            font.bold: true
        }
    }

    background: Rectangle {
        readonly property bool lit: button.pressed || button.checked
        radius: Units.gu(0.6)
        visible: button.appearance !== "plain" || button.pressed
        color: button.appearance === "plain" ? "#30000000"
             : button.appearance === "overlay" ? (button.pressed ? "#55ffffff" : button.checked ? "#33ffffff" : "transparent")
             : lit ? "#1d1d1d" : "transparent"
        border.color: button.appearance === "toolbar" && lit ? "#0c0c0c" : "transparent"
    }
}
