/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
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

import QtQuick 2.6
import QtQuick.Controls 2.0
import LunaNext.Compositor 0.1

FakeWindowBase {
    id: fakeOverlayWindow

    appId: "org.webosports.tests.fakeOverlayWindow"
    windowType: WindowType.Overlay

    x: Math.random()*200
    y: parent.height - height
    width: 300 + Math.random()*150
    height: 150 + Math.random()*50

    property alias scale: windowRectangle.scale

    Rectangle {
        id: windowRectangle

        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "grey" }
            GradientStop { position: 1.0; color: "red" }
        }

        Row {
            anchors.centerIn: parent

            Button {
                text: "Hide me"
                onClicked: {
                    fakeOverlayWindow.visible = false;
                    showTimer.start();
                }

                Timer {
                    id: showTimer
                    interval: 3000
                    onTriggered: fakeOverlayWindow.visible = true
                }
            }
            Button {
                text: "Key"
                checkable: true
            }
        }
    }
}
