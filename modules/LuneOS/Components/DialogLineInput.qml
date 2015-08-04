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
import QtQuick.Window 2.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import LunaNext.Common 0.1

Rectangle {
    id: dialogLineInput
    width: Units.gu(26)
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: Units.gu(-2)
    property alias text: input.text
    property alias echoMode: input.echoMode
    signal accepted()
    height: Units.gu(3)
    color: "#fefefe"

    border {
        width: 1
        color: "#aeaeae"
    }

    smooth: true
    radius: 3
    clip: true

    TextInput {
        id: input
        width: parent.width
        anchors.left: parent.left
        clip: true
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        font.family: "Prelude"
        font.pixelSize: FontUtils.sizeToPixels("large")
        color: "#444444"
        onAccepted: dialogLineInput.accepted()
    }
}
