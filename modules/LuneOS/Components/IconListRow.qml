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
 * A row of a dark list - a library, an album, a playlist: a picture on the
 * left (iconSource, or the item picture makes, a cover say), a title and a
 * grey subtitle, a small badge on the picture's corner (a cloud account's
 * mark), a spinner while busy, and a lit background when selected.
 *
 *   IconListRow {
 *       title: album.name; subtitle: count; badge: cloudIcon
 *       picture: Component { PlaceholderImage { source: cover } }
 *       onClicked: open(album)
 *   }
 */
ItemDelegate {
    id: row

    property string title
    property string subtitle
    property url iconSource
    // Shown in the picture's place instead of iconSource, when set
    property Component picture: null
    property url badge
    property bool busy: false
    property bool selected: false

    width: parent ? parent.width : 0
    height: Units.gu(7)
    padding: 0
    background: Rectangle {
        color: row.pressed ? "#333333" : (row.selected ? "#3c4a57" : "transparent")
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#1a1a1a"
        }
    }
    contentItem: Item {
        Item {
            id: pictureBox
            anchors.left: parent.left
            anchors.leftMargin: Units.gu(1.5)
            anchors.verticalCenter: parent.verticalCenter
            width: Units.gu(5)
            height: width

            Image {
                objectName: "rowIcon"
                anchors.fill: parent
                anchors.margins: Units.gu(0.5)
                visible: row.picture === null
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(Math.ceil(width), Math.ceil(height))
                source: visible ? row.iconSource : ""
            }
            Loader {
                anchors.fill: parent
                active: row.picture !== null
                sourceComponent: row.picture
            }
            Image {
                objectName: "rowBadge"
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -Units.gu(0.4)
                width: Units.gu(2.2)
                height: width
                visible: row.badge.toString() !== ""
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(Math.ceil(width), Math.ceil(height))
                source: row.badge
            }
        }
        Column {
            anchors.left: pictureBox.right
            anchors.leftMargin: Units.gu(1.5)
            anchors.right: spinner.left
            anchors.rightMargin: Units.gu(1)
            anchors.verticalCenter: parent.verticalCenter
            Label {
                objectName: "rowTitle"
                width: parent.width
                text: row.title
                color: "white"
                elide: Text.ElideRight
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }
            Label {
                objectName: "rowSubtitle"
                width: parent.width
                visible: text !== ""
                text: row.subtitle
                color: "#9a9a9a"
                elide: Text.ElideRight
                font.pixelSize: FontUtils.sizeToPixels("small")
            }
        }
        BusyIndicator {
            id: spinner
            objectName: "rowBusy"
            anchors.right: parent.right
            anchors.rightMargin: Units.gu(1)
            anchors.verticalCenter: parent.verticalCenter
            width: row.busy ? Units.gu(3.5) : 0
            height: Units.gu(3.5)
            running: row.busy
            visible: row.busy
        }
    }
}
