/*
 * Copyright (C) 2015 Christophe Chapuis <chris.chapuis@gmail.com>
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

CheckBoxStyle {
    id: checkboxStyle

    label: Text {
            text: control.text
            font.family: "Lato"
            font.pixelSize: FontUtils.sizeToPixels("medium")
            font.weight: Font.Normal
            font.italic: true
            color: "#333333"

    }

    indicator: Rectangle {

            width: Units.gu(3.2)
            height: Units.gu(3.2)
            radius: Units.gu(1.8)
            color: "#FFFFFF"
            border.color: "#646464"
            border.width:
                if(control.checked){
                    Units.gu(0)
                }
                else{
                    Units.gu(0.2)
                }



                Rectangle {
                    visible: control.checked

                    width: Units.gu(3.2)
                    height: Units.gu(3.2)
                    radius: Units.gu(1.8)
                    color: "#FFB80D"
                    anchors.margins: 0
                    anchors.fill: parent
                }
            }
}
