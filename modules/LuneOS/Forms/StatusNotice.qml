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

// Theme specific properties
import QtQuick.Controls.LuneOS 2.0
// Units & font sizes
import LunaNext.Common 0.1
import LuneOS.Forms 1.0

/*
 * One line of trouble under the header that the user can dismiss - Remote's
 * "no transmitter" or "that key did not go out". Same colours as
 * ServiceUnavailableNotice, so it reads as the same kind of message. A title
 * goes in bold above the text ("Sync failed" / what the server said).
 */
Rectangle {
    id: notice

    property alias title: titleLabel.text
    property alias text: noticeLabel.text

    signal dismissed()

    implicitHeight: Math.max(words.implicitHeight, closeButton.implicitHeight) + Units.gu(2)
    height: visible ? implicitHeight : 0

    color: Colors.noticeBackground
    border.color: Colors.noticeBorder
    border.width: 1
    radius: Units.gu(0.6)

    Column {
        id: words

        anchors.left: parent.left
        anchors.right: closeButton.left
        anchors.margins: Units.gu(1.5)
        anchors.verticalCenter: parent.verticalCenter

        Label {
            id: titleLabel
            objectName: "noticeTitle"

            width: parent.width
            visible: text !== ""
            wrapMode: Text.WordWrap
            color: Colors.noticeText
            font.bold: true
            font.pixelSize: FontUtils.sizeToPixels("small")
        }
        Label {
            id: noticeLabel

            width: parent.width
            wrapMode: Text.WordWrap
            color: Colors.noticeText
            font.pixelSize: FontUtils.sizeToPixels("small")
        }
    }

    Button {
        id: closeButton
        objectName: "noticeCloseButton"

        anchors.right: parent.right
        anchors.rightMargin: Units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        width: Units.gu(5)

        text: "✕"
        flat: true
        LuneOSButton.textColor: Colors.noticeText

        onClicked: notice.dismissed()
    }
}
