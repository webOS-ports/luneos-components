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
import QtQuick.Controls 2.0
import LunaNext.Common 0.1

Rectangle {
    id: dialogLineInput
    width: Units.gu(26)
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: Units.gu(-2)
    property alias text: input.text
    property alias echoMode: input.echoMode
    property alias inputMethodHints: input.inputMethodHints
    property alias passwordCharacter: input.passwordCharacter
    // The line's TextInput, for what is not passed on here.
    readonly property alias textInput: input
    signal accepted()

    // What the line holds with what the keyboard has not committed yet put
    // in at the cursor: in T9 the last letter waits there, and a tap on a
    // dialog's key would otherwise leave it out ("secre" for "secret").
    function typedText() {
        var text = input.text;
        var at = Math.max(0, Math.min(text.length, input.cursorPosition));
        return text.substring(0, at) + input.preeditText + text.substring(at);
    }
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
        // Room between the frame and the first and last letters.
        leftPadding: Units.gu(1)
        rightPadding: Units.gu(1)
        clip: true
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        font.family: "Prelude"
        font.pixelSize: FontUtils.sizeToPixels("large")
        color: "#444444"
        selectionColor: "#FFEA58"
        selectedTextColor: "#000000"
        onAccepted: dialogLineInput.accepted()
    }
}
