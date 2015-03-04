/*
 * Copyright (C) 2015 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2013 Tomasz Olszak <olszak.tomasz@gmail.com>
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:

 * 1. Redistributions of source code must retain the copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


import QtQuick 2.2
import QtQuick.Controls 1.1
import LuneOS.Components 1.0

Page {
    id: page

    width: parent.width
    height: parent.height

    Rectangle {
        id:popup
        visible: false;
        anchors.fill: parent
        anchors.margins: 50
        color: "lightgrey"
        border.color: "blue"
        border.width: 1
        z:1

        Text {
            text:"Left"
            font.pixelSize: 60
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text:"Right"
            font.pixelSize: 60
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text:"Top"
            font.pixelSize: 60
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Button {
            anchors.bottom: parent.bottom
            text: "Close"
            width: 200
            onClicked: popup.hide()
            anchors.horizontalCenter: parent.horizontalCenter
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: true
        }

        function popup() {
            visible = true;
        }

        function hide() {
            visible = false;
        }
    }

    Column {
        spacing: 40
        anchors.centerIn: parent

        CheckBox {
            text:"Check box"
            onClicked: popup.popup()
        }

        CheckBox {
            text:"Check box 2"
            onClicked: if (pageStack) pageStack.pop()
        }

        CheckBox {
            text:"Inverted"
            x:100
            width:root.width/2
            height: root.height/10
            styleHints: {"color": "orange","pressedColor": "red"}
            LayoutMirroring.enabled: true
            LayoutMirroring.childrenInherit: true
        }

        CheckBox {
            text:"H Switch"
            onCheckedChanged: mSwitch2.checked = checked

            Switch {
                id:mSwitch2
                checked: parent.checked
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onCheckedChanged: parent.checked = checked
            }
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Go back"
            onClicked: if (pageStack) pageStack.pop()
        }
    }
}
