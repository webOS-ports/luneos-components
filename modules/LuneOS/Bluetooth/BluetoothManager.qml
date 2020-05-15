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
// LuneOS Bluetooth wrapper
import org.kde.bluezqt 1.0 as BluezQt

Item {
    id: root

    property alias powered: bluetoothTech.powered
    readonly property bool bluetoothOperational: btManager.bluetoothOperational
    readonly property bool initializing: powered && !bluetoothOperational
    property bool discoveringMode: false
    readonly property bool discoverable: bluetoothOperational && btManager.usableAdapter.discoverable
    readonly property bool connected: bluetoothOperational && btManager.usableAdapter.connected /*remark: connected is specific to Mer's version*/

    property QtObject btManager: BluezQt.Manager
    property QtObject connectingDevice;

    function connectDeviceAddress(btDeviceAddress)
    {
        var pendingCall;

        function __doConnect(device) {
            pendingCall = device.connectToDevice();
            pendingCall.finished.connect(function(call) {
                connectingDevice = null;
            });
        }

        if (btManager.bluetoothOperational) {
            var device = btManager.deviceForAddress(btDeviceAddress);
            if(root.connectingDevice === device || device.connected) {
                pendingCall = device.disconnectFromDevice();
                root.connectingDevice = null;
            }
            else {
                if(connectingDevice) {
                    connectingDevice.disconnectFromDevice();
                }

                connectingDevice = device;
                if(!device.paired) {
                    device.onPairedChanged.connect(function() {
                        if(connectingDevice === device && device.paired) {
                            console.log("Pairing has succeeded, connecting now...");
                            __doConnect(device);
                        }
                    });
                    pendingCall = device.pair();
                    pendingCall.finished.connect(function(call) {
                        console.log("Pairing call is now finished.");
                    });
                }
                else {
                    __doConnect(device);
                }
            }
        }

        return pendingCall;
    }

    function disconnectDeviceAddress(btDeviceAddress)
    {
        var pendingCall;

        var device = btManager.deviceForAddress(btDeviceAddress);
        if(connectingDevice === device) {
            connectingDevice = null;
        }
        pendingCall = device.disconnectFromDevice();

        return pendingCall;
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

    /* Bindings to keep the discovering mode updated */
    Connections {
        target: btManager
        function onUsableAdapterChanged() {
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
