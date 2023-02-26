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

import QtQuick 2.0
import QtQuick.Controls 2.0

FakeWindowBase {
    id: fakeDashboardWindow

    appId: "org.webosports.tests.fakeDashboardWindow"
    type: "_WEBOS_WINDOW_TYPE_FLOATING"

     windowProperties: { "LuneOS_window": "dashboard", "LuneOS_dashheight": 50 + Math.random()*50 }

    Rectangle {
        id: windowRectangle

        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "grey" }
            GradientStop { position: 1.0; color: Qt.rgba(Math.random(),Math.random(),1,1) }
        }

        Row {
            anchors.centerIn: parent

            Button {
                text: "OK"
                onClicked: fakeDashboardWindow.destroy()
            }
            Button {
                text: "Cancel"
                checkable: true
            }
        }
    }
}
