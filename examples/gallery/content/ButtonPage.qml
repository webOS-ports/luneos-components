/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2015 Christophe Chapuis <chris.chapuis@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.1
import LuneOS.Components 1.0
import LunaNext.Common 0.1
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.0

Page {
    width: parent.width
    height: parent.height

    Column {
        spacing: 40
        anchors.centerIn: parent

        Button {
            anchors.margins: 20
            text: "Press me"
            styleHints: {color:"orange"; pressedColor:"red"}
        }

        Button {
            anchors.margins: 20
            text: "Press me too"
        }

        Button {
            anchors.margins: 20
            enabled:false
            text: "Dont press me"
        }

        TextField {
            width: Units.gu(30)
            placeholderText: "A disabled one"
            enabled: false
        }
    }

    Button {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Units.gu(1)
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Go back"
        onClicked: if (pageStack) pageStack.pop()
    }
}
