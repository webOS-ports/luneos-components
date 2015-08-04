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

            Item {
            id: staticContent
            anchors.centerIn: parent
            anchors.fill: parent

            Text {
                id: titleText
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: "Prelude"
                font.pixelSize: 16
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                id: messageText
                anchors.left: parent.left
                anchors.leftMargin: Units.gu(2)
                anchors.top: parent.top
                anchors.topMargin: Units.gu(2)
                font.family: "Prelude"
                color: "#292929"
                font.pixelSize: FontUtils.sizeToPixels("12pt")

            }

            Column {
                id: dynamicColumn
                spacing: Units.gu(0.5)
                anchors {
                    bottom: staticContent.bottom
                    horizontalCenter: staticContent.horizontalCenter
                }
            }
        }
    }
}
