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
 * A heading between a dark list's groups - "LIBRARIES", "ALL ALBUMS" -
 * that can be tapped, to fold its group away (open says which way it is).
 */
Rectangle {
    id: divider

    property alias text: label.text
    property bool open: true
    property alias textColor: label.color
    signal clicked()

    width: parent ? parent.width : 0
    height: Units.gu(4)
    color: "#1f1f1f"

    Label {
        id: label
        objectName: "dividerLabel"
        anchors.left: parent.left
        anchors.leftMargin: Units.gu(1.5)
        anchors.right: parent.right
        anchors.rightMargin: Units.gu(1.5)
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        color: "#a0a0a0"
        font.bold: true
        font.pixelSize: FontUtils.sizeToPixels("small")
    }
    MouseArea {
        anchors.fill: parent
        onClicked: divider.clicked()
    }
}
