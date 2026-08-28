/*
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; see the file COPYING.  If not, see
 * <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.0
import LunaNext.Common 0.1

Item {
    id: dialog

    anchors.fill: parent
    z: 1000

    // We want to be a child of the root item so that we can cover
    // the whole scene with our "dim" overlay.

    property alias title: titleText.text
    property alias message: messageText.text
    property alias dialogHeight: dialogWindow.height
    property alias dialogWidth: dialogWindow.width

    default property alias __children: dynamicColumn.children

    MouseArea {
        id: mouseBlocker
        anchors.fill: parent
        onPressed: mouse.accepted = true
        preventStealing: true

        // FIXME: This does not block touch events :(
    }

    Rectangle {
        id: dimBackground
        anchors.fill: parent
        color: "black"
        opacity: 0.4
    }


    Rectangle {
            id: dialogWindow
            color: "transparent"
            height: Units.gu(15.0)
            smooth: true
            radius: 10


            anchors.centerIn: parent

            Image {
                id: leftImageTop
                anchors.top: parent.top
                anchors.left: parent.left
                source: "images/dialog-left-top.png"
                height: Units.gu(2.5)
                width: Units.gu(2.5)
            }
            Image {
                id: leftImageMiddle
                height: parent.height - leftImageTop.height - leftImageBottom.height
                anchors.top: leftImageTop.bottom
                anchors.left: parent.left
                source: "images/dialog-left-middle.png"
                fillMode: Image.Stretch
                width: Units.gu(2.5)
            }
            Image {
                id: leftImageBottom
                height: Units.gu(2.5)
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                source: "images/dialog-left-bottom.png"

                width: Units.gu(2.5)
            }

            Image {
                id: centerImageTop
                height: Units.gu(2.5)
                anchors.left: leftImageTop.right
                anchors.top: parent.top
                source: "images/dialog-center-top.png"
                width: parent.width - leftImageTop.width - rightImageTop.width
            }
            Image {
                id: centerImageMiddle
                height: parent.height - centerImageTop.height - centerImageBottom.height
                anchors.left: leftImageMiddle.right
                anchors.top: centerImageTop.bottom
                source: "images/dialog-center-middle.png"
                width: parent.width - leftImageTop.width - rightImageTop.width
                fillMode: Image.Stretch
            }
            Image {
                id: centerImageBottom
                height: Units.gu(2.5)
                anchors.left: leftImageBottom.right
                anchors.bottom: parent.bottom
                source: "images/dialog-center-bottom.png"
                width: parent.width - leftImageBottom.width - rightImageBottom.width
            }

            Image {
                id: rightImageTop
                anchors.right: parent.right
                anchors.top: parent.top
                source: "images/dialog-right-top.png"
                width: Units.gu(2.5)
                height: Units.gu(2.5)
            }
            Image {
                id: rightImageMiddle
                anchors.right: parent.right
                anchors.top: rightImageTop.bottom
                source: "images/dialog-right-middle.png"
                width: Units.gu(2.5)
                height: parent.height - rightImageTop.height - rightImageBottom.height
                fillMode: Image.Stretch
            }

            Image {
                id: rightImageBottom
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                source: "images/dialog-right-bottom.png"
                width: Units.gu(2.5)
                height: Units.gu(2.5)
            }

            // Held inside the frame: the artwork's own edge is a couple of
            // grid units thick, and content laid flush against the dialog
            // would sit on top of it.
            Item {
            id: staticContent
            anchors.fill: parent
            anchors.margins: Units.gu(1.6)

            Text {
                id: titleText
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.family: "Prelude"
                color: "#3b3b3b"
                font.pixelSize: 16
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            // Under the title rather than over it: both were anchored to the
            // top of the dialog, so a dialog with both printed them on top of
            // one another.
            Text {
                id: messageText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: titleText.visible && titleText.text.length > 0
                                 ? titleText.bottom : parent.top
                anchors.topMargin: Units.gu(1)
                wrapMode: Text.Wrap
                font.family: "Prelude"
                color: "#292929"
                font.pixelSize: FontUtils.sizeToPixels("12pt")

            }

            // The buttons a dialog is given, stacked against its foot. The
            // margin used to live on DialogButton itself, which anchored to
            // its parent's bottom -- and an item that anchors itself cannot be
            // laid out by a Column, so a dialog offering a choice of more than
            // one button drew them all on top of each other.
            Column {
                id: dynamicColumn
                spacing: Units.gu(0.5)
                anchors {
                    bottom: staticContent.bottom
                    bottomMargin: Units.gu(1)
                    horizontalCenter: staticContent.horizontalCenter
                }
            }
        }
    }
}
