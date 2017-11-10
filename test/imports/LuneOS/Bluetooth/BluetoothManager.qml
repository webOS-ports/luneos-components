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
    readonly property bool discoverable: bluetoothOperational && btManager.usableAdapter.discoverable
    readonly property bool connected: bluetoothOperational && btManager.usableAdapter.connected /*remark: connected is specific to Mer's version*/

    property QtObject btManager: QtObject {
        property bool bluetoothOperational: false
        property QtObject usableAdapter: QtObject {
            property bool connected: false
            property bool discovering: false
            property bool discoverable: false
            function startDiscovery() { discovering = true; }
            function stopDiscovery() { discovering = false; }
        }
        function deviceForAddress(btDeviceAddress) {
        }
        property LuneOSBluetoothAgent _currentAgent
        function registerAgent(agent) {
            _currentAgent = agent;
        }
    }
    property QtObject connectingDevice;

    function newLuneosRequestComponent(iRequestType, acceptFct) {
        var luneosRequestComponent = Qt.createComponent(Qt.resolvedUrl("LuneOSBluetoothRequest.qml"));
        var newRequestObj = luneosRequestComponent.createObject(root, {requestType: iRequestType});
        if(typeof acceptFct !== 'undefined') newRequestObj.onAccept.connect(acceptFct);

        return newRequestObj;
    }

    function connectDeviceAddress(btDeviceAddress)
    {
        if(!btManager._currentAgent) return;
        // test pairing
        btManager._currentAgent.requestPasskeyFromUser({name: btDeviceAddress}, newLuneosRequestComponent(1, __passKeyEntered));
        function __passKeyEntered(acceptedValue) {
            btManager._currentAgent.displayPasskeyToUser({name: btDeviceAddress}, acceptedValue, acceptedValue);
        }
    }

    function disconnectDeviceAddress(btDeviceAddress)
    {
        // disconnect
        // unpair
    }

    function setDiscoverable(isDiscoverable)
    {
        if(btManager && btManager.usableAdapter) {
            btManager.usableAdapter.discoverable = isDiscoverable;
        }
    }

    TechnologyModel {
        id: bluetoothTech
        name: "bluetooth"
    }
    Timer {
        running: true
        repeat: false
        interval: 200
        onTriggered: btManager.bluetoothOperational = true;
    }
}
