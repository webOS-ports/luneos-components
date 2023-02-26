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

import QtQuick 2.12
import QtQuick.Window 2.12

import Eos.Window 0.1

Item {
    id: window
    property string title: ""
    property string subtitle: ""
    property string type: "_WEBOS_WINDOW_TYPE_CARD"
    property point mousePosition: Qt.point(-1,-1)
    property string appId: ""
    property int displayAffinity: 0
    property bool keepAlive: false
    property int locationHint: 0
    property int windowState: 0
    property var windowProperties
    property EosRegion inputRegion: EosRegion {}
    property int keyMask: 0
    property bool cursorVisible: false
    property string addon: ""
    property string launchParams: ""
    property int parentWinId: 0
    property var userData;

    signal exposedChanged(bool exposed)

    function takeFocus() {
        window.focus = true;
    }

    function changeSize(newSize) {
        window.width = newSize.width;
        window.height = newSize.height;
    }
}
