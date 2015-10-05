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
    id: webEngineDialog

    anchors.fill: parent

    property string bgopacity: "0"
    property alias title: titleText.text
    property alias message: messageText.text
    property alias dialogHeight: dialogWindow.height
    property alias dialogWidth: dialogWindow.width
    property alias dialogIcon: webEngineDialogIcon.visible

    default property alias __children: dynamicColumn.children

    MouseArea {
        id: mouseBlocker
        anchors.fill: parent
        onPressed: mouse.accepted = true
        preventStealing: true

        // FIXME: This does not block touch events :(
    }

    Rectangle {
        id: dialogWindow
        color: "#343434"
        height: Units.gu(21.8)
        smooth: true
        radius: 10
        opacity: 0.9
        anchors.top: parent.top
        anchors.topMargin: Units.gu(1)
        anchors.right: parent.right
        anchors.rightMargin: Units.gu(2.5)


        Image {
            id: leftImageTop
            anchors.top: parent.top
            anchors.left: parent.left
            source: "images/dialog-left-top.png"
            height: Units.gu(2.5)
            width: Units.gu(2.5)
            opacity: 0
        }
        Image {
            id: leftImageMiddle
            height: parent.height - leftImageTop.height - leftImageBottom.height
            anchors.top: leftImageTop.bottom
            anchors.left: parent.l3eft
            source: "images/dialog-left-middle.png"
            fillMode: Image.Stretch
            width: Units.gu(2.5)
            opacity: 0
        }
        Image {
            id: leftImageBottom
            height: Units.gu(2.5)
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            source: "images/dialog-left-bottom.png"
            width: Units.gu(2.5)
            opacity: 0
        }

        Image {
            id: centerImageTop
            height: Units.gu(2.5)
            anchors.left: leftImageTop.right
            anchors.top: parent.top
            source: "images/dialog-center-top.png"
            width: parent.width - leftImageTop.width - rightImageTop.width
            opacity: 0
        }
        Image {
            id: centerImageMiddle
            height: parent.height - centerImageTop.height - centerImageBottom.height
            anchors.left: leftImageMiddle.right
            anchors.top: centerImageTop.bottom
            source: "images/dialog-center-middle.png"
            width: parent.width - leftImageTop.width - rightImageTop.width
            fillMode: Image.Stretch
            opacity: 0
        }
        Image {
            id: centerImageBottom
            height: Units.gu(2.5)
            anchors.left: leftImageBottom.right
            anchors.bottom: parent.bottom
            source: "images/dialog-center-bottom.png"
            width: parent.width - leftImageBottom.width - rightImageBottom.width
            opacity: 0
        }

        Image {
            id: rightImageTop
            anchors.right: parent.right
            anchors.top: parent.top
            source: "images/dialog-right-top.png"
            width: Units.gu(2.5)
            height: Units.gu(2.5)
            opacity: 0
        }
        Image {
            id: rightImageMiddle
            anchors.right: parent.right
            anchors.top: rightImageTop.bottom
            source: "images/dialog-right-middle.png"
            width: Units.gu(2.5)
            height: parent.height - rightImageTop.height - rightImageBottom.height
            fillMode: Image.Stretch
            opacity: 0
        }

        Image {
            id: rightImageBottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            source: "images/dialog-right-bottom.png"
            width: Units.gu(2.5)
            height: Units.gu(2.5)
            opacity: 0
        }

        Item {
            id: staticContent
            anchors.centerIn: parent
            anchors.fill: parent

            Text {
                id: titleText
                width: parent.width
                anchors.left: parent.left
                anchors.leftMargin: Units.gu(2)
                anchors.top: parent.top
                anchors.topMargin: Units.gu(1)
                font.family: "Prelude"
                font.pixelSize: FontUtils.sizeToPixels("16pt")
                font.weight: Font.DemiBold
                color: "white"
                elide: Text.ElideRight
                smooth: true
            }

            Text {
                id: messageText
                anchors.left: parent.left
                anchors.leftMargin: Units.gu(2)
                anchors.top: titleText.bottom
                anchors.topMargin: Units.gu(0.5)
                font.family: "Prelude"
                font.bold: true
                color: "#FFFFFF"
                font.pixelSize: FontUtils.sizeToPixels("12pt")
                wrapMode: Text.WordWrap
                //text: "Long test to see how it wraps and what we want to do with that"
                width: parent.width * 2/3
                smooth: true

            }
            Image {
                id: webEngineDialogIcon
                source: "images/icon-warning.png"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: Units.gu(0.8)
                anchors.rightMargin: Units.gu(0.8)
                height: Units.gu(5.9)
                width: Units.gu(5.9)
            }

            Column {
                id: dynamicColumn
                spacing: Units.gu(0.5)
                z:10000
                opacity: 1
                anchors {
                    bottom: staticContent.bottom
                    horizontalCenter: staticContent.horizontalCenter
                }
            }
        }
    }
}
