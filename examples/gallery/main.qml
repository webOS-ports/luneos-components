/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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
import QtQuick.Controls 1.1
import LunaNext.Common 0.1
import LuneOS.Application 1.0

ApplicationWindow {
    id: window

    visible: true

    ListModel {
        id: pageModel

        ListElement {
            title: "Buttons"
            page: "ButtonsPage.qml"
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
    }

    StackView {
        id: pageStack
        anchors.fill: parent

        initialItem: Item {
            width: parent.width
            height: parent.height

            ListView {
                id: listView
                model: pageModel
                anchors.fill: parent

                delegate: Item {
                    width: parent.width
                    height: Units.gu(10)

                    Rectangle {
                        anchors.fill: parent
                        color: "#11ffffff"
                    }

                    Text {
                        color: "white"
                        font.pixelSize: FontUtils.sizeToPixels("large")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 30
                        text: title
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 15
                        height: 1
                        color: "#424246"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl(page));
                        }
                    }
                }
            }
        }
    }
}
