/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.0
import LunaNext.Common 0.1

ButtonStyle {
    id: buttonStyle

    padding {
        left: Units.gu(2)
        right: Units.gu(2)
    }

    background: Item {

        Text {
            id: decoratorLeft
            text: "( "
            font.family: "Lato"
            font.pixelSize: FontUtils.sizeToPixels("x-large")
            font.weight: Font.Bold
            anchors.left: parent.left
            anchors.leftMargin:
                if(control.pressed){
                    Units.gu(-0.5)
                }
                else{
                   Units.gu(0)
                }
            color: "#4b4b4b"
            opacity: control.enabled ? 1.0 : 0.4

            Behavior on anchors.leftMargin {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Text {
            id: decoratorRight
            text: " )"
            font.family: "Lato"
            font.pixelSize: FontUtils.sizeToPixels("x-large")
            font.weight: Font.Bold
            anchors.right: parent.right
            anchors.rightMargin: control.pressed ? Units.gu(-0.5) : Units.gu(0)
            color: "#4b4b4b"
            opacity: control.enabled ? 1.0 : 0.4

            Behavior on anchors.rightMargin {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    label: Item {
        implicitWidth: text.width
        implicitHeight: text.height

        Text {
            id: text
            text: control.text
            font.family: "Lato"
            font.pixelSize: FontUtils.sizeToPixels("medium")
            font.weight: Font.Bold
            font.italic: true
            lineHeightMode: Text.ProportionalHeight
            lineHeight: 2
            verticalAlignment: Text.AlignVCenter
            color: "#323231"
            opacity: control.enabled ? 1.0 : 0.4
        }

        Rectangle {
            anchors.top: text.bottom
            anchors.topMargin: Units.gu(0)
            width: text.width
            visible: control.pressed
            height: Units.gu(0.1)
            color: "#69cdff"
        }
    }
}
