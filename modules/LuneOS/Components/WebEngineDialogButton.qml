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

Rectangle {

    id: button

    property alias text: buttonText.text
    property alias fontcolor: buttonText.color
    property alias buttonWidth: button.width

    signal clicked();

    height: Units.gu(3.8)
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Units.gu(2)
    radius: 4
    color: "#4b4b4b"
    opacity: 1
    Item {
        id: buttonBG
        anchors.centerIn: parent
        height: parent.height
        width:  button.width
        opacity: 1


    Image {
        id: confirmImageLeft
        source: "images/button-up-left.png"
        width: Units.gu(1.9)
        height: parent.height
        fillMode: Image.Stretch
        anchors.left: buttonBG.left
        opacity: 1
    }
    Image {
        id: confirmImageCenter
        source: "images/button-up-center.png"
        width:  button.width - confirmImageLeft.width - confirmImageRight.width
        height: parent.height
        opacity: 1
        fillMode: Image.Stretch
        anchors.left: confirmImageLeft.right
        anchors.right: confirmImageRight.left
    }

    Image {
        id: confirmImageRight
        source: "images/button-up-right.png"
        width: Units.gu(1.9)
        height: parent.height
        fillMode: Image.Stretch
        anchors.right: buttonBG.right
        opacity: 1
    }

    }

    Text {
        id: buttonText
        anchors.centerIn: parent
        font.family: "Prelude"
        font.pixelSize: FontUtils.sizeToPixels("14pt")
        font.bold: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: button.clicked()
    }
}

