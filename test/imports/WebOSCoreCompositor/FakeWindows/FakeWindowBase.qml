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

import LuneOS.Service 1.0

Item {
    id: fakeWindowBase
    property string title: ""
    property string type: "_WEBOS_WINDOW_TYPE_CARD"
    property string appId: "org.webosports.tests.fakewindowbase"
    property var windowProperties
    property string launchParams: ""
    property int parentWinId: 0
    property var userData;

    property variant compositor

    signal exposedChanged(bool exposed)

    property QtObject lunaNextLS2Service: LunaService {
        id: lunaNextLS2Service
        name: "org.webosports.luna"
    }

    function takeFocus() {
        fakeWindowBase.focus = true;
    }

    function changeSize(newSize) {
        fakeWindowBase.width = newSize.width;
        fakeWindowBase.height = newSize.height;
    }

    Component.onDestruction: if(compositor) compositor.closeWindow(fakeWindowBase);
}
