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



TabViewStyle {
    id: tabviewStyle

    property int myname
    frameOverlap: 1
    tabsAlignment: Qt.AlignHCenter

    // tabOverlap: -10
            tab: Rectangle {
                id: mytab
                color: styleData.selected ? "orange" :"green"
                border.color:  "steelblue"
                implicitWidth: Math.max(text.width + 4, 80)
                implicitHeight: 50
                radius: 2
                property int myname: styleData.title
                Text {
                    id: text
                    font.family: "Lato"
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                    font.weight: Font.Bold
                    font.italic: true
                    anchors.centerIn: parent
                    text: myname
                    color: styleData.selected ? "red" : "black"
                }
            }



            tabBar: Item {
                        anchors.fill: parent
                        id: myTabbar

                        Rectangle{
                            id: blueBlock
                            color: "blue"
                            width: 20
                            height: parent.height
                            anchors.right: myTabbar.horizontalCenter
                            anchors.rightMargin: 159

                            Text {
                                id: decoratorLeft
                                text: "( "
                                font.family: "Lato"
                                font.pixelSize: FontUtils.sizeToPixels("x-large")
                                font.weight: Font.Bold

                             }
                        }
                }











            //leftCorner:
             //   Rectangle {
             //   implicitWidth: 100
            //        implicitHeight: 100
            //        color: "red"
            //
           // }

}
