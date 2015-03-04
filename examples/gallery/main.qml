/*
 * Copyright (C) 2015 Christophe Chapuis <chris.chapuis@gmail.com>
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
import LuneOS.Components 1.0

ApplicationWindow {
    id: window

    visible: true

    width: 480
    height: 640

    ListModel {
        id: pageModel
        ListElement {
            title: "Buttons"
            page: "content/ButtonPage.qml"
        }
        ListElement {
            title: "Sliders"
            page: "content/SliderPage.qml"
        }
        ListElement {
            title: "ProgressBar"
            page: "content/ProgressBarPage.qml"
        }
        ListElement {
            title: "Tabs"
            page: "content/TabBarPage.qml"
        }
        ListElement {
            title: "CheckBoxes"
            page: "content/CheckBoxPage.qml"
        }
        ListElement {
            title: "SplitView"
            page: "content/SplitViewPage.qml"
        }
        ListElement {
            title: "TextField"
            page: "content/TextInputPage.qml"
        }
    }

    StackView {
        id: pageStack
        anchors.fill: parent

        initialItem: Page {

            ListView {
                id: listView
                model: pageModel
                anchors.fill: parent

                delegate: Item {
                    width: parent.width
                    height: Units.gu(10)

                    Text {
                        color: "black"
                        font.pixelSize: FontUtils.sizeToPixels("large")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 30
                        text: title
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
