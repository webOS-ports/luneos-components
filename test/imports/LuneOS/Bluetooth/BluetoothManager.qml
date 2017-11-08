/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
 * Copyright (C) 2015 Nikolay Nizov <nizovn@gmail.com>
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
pragma Singleton

import QtQuick 2.0
// Connman
import Connman 0.2

Item {
    id: root

    property alias powered: bluetoothTech.powered
    readonly property bool bluetoothOperational: btManager.bluetoothOperational
    readonly property bool initializing: powered && !bluetoothOperational
    property bool discoveringMode: false
    readonly property bool connected: bluetoothOperational && btManager.usableAdapter.connected /*remark: connected is specific to Mer's version*/

    property QtObject btManager: QtObject {
        property bool bluetoothOperational: true
        property QtObject usableAdapter: QtObject {
            property bool connected: false
            property bool discovering: false
            function startDiscovery() { discovering = true; }
            function stopDiscovery() { discovering = false; }
        }
        function deviceForAddress(btDeviceAddress) {
        }
    }
    property QtObject connectingDevice;

    function connectDeviceAddress(btDeviceAddress)
    {
    }

    function disconnectDeviceAddress(btDeviceAddress)
    {
    }

    TechnologyModel {
        id: bluetoothTech
        name: "bluetooth"
    }

    /* Bindings to keep the discovering mode updated */
    Connections {
        target: btManager
        onUsableAdapterChanged: {
            if(btManager.usableAdapter && root.discoveringMode)
                btManager.usableAdapter.startDiscovery();
        }
    }
    onDiscoveringModeChanged: {
        if(btManager.usableAdapter && root.discoveringMode && !btManager.usableAdapter.discovering) {
            console.log("Starting bluetooth discovery.");
            btManager.usableAdapter.startDiscovery();
        }
        else if(btManager.usableAdapter && !root.discoveringMode && btManager.usableAdapter.discovering) {
            console.log("Stopping bluetooth discovery.");
            btManager.usableAdapter.stopDiscovery();
        }
    }
    Component.onCompleted: {
        if(btManager.usableAdapter && root.discoveringMode && !btManager.usableAdapter.discovering) {
            console.log("Starting bluetooth discovery.");
            btManager.usableAdapter.startDiscovery();
        }
    }
    Component.onDestruction: {
        if(btManager.usableAdapter && btManager.usableAdapter.discovering) {
            console.log("Stopping bluetooth discovery.");
            btManager.usableAdapter.stopDiscovery();
        }
    }
}
