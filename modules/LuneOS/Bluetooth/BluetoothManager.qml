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

import "BluetoothPolicy.js" as Policy

Item {
    id: root

    property alias powered: bluetoothTech.powered
    // Not btManager.bluetoothOperational: BluezQt also requires every
    // Bluetooth rfkill switch to be unblocked, and some devices carry one
    // that never is - on the BlackBerry KEY2 (WCN3990) the vendor bt_power
    // switch stays soft-blocked because the chip has no enable GPIO, while
    // the Android HAL powers it through /dev/btpower. Power is connman's
    // call (see "powered" above); once it powers the adapter off, BluezQt
    // drops it as the usable adapter anyway.
    readonly property bool bluetoothOperational: btManager.operational && btManager.usableAdapter !== null
    readonly property bool initializing: powered && !bluetoothOperational
    // Set while a device list is on screen. Discovery then runs for
    // discoveryTimeoutMs and stops; searchAgain() runs another.
    property bool discoveringMode: false
    property int discoveryTimeoutMs: Policy.discoveryTimeoutMs
    // The adapter is searching right now - for a "Searching..." indicator.
    readonly property bool discovering: bluetoothOperational && btManager.usableAdapter.discovering === true
    readonly property bool discoverable: bluetoothOperational && btManager.usableAdapter.discoverable
    // BluezQt's Adapter has no "connected" (Mer's had); undefined is false.
    readonly property bool connected: bluetoothOperational && btManager.usableAdapter.connected === true

    // This search has run its time; cleared by searchAgain() and by
    // discoveringMode being set again.
    property bool _discoveryTimedOut: false

    property QtObject btManager: BluezQt.Manager
    property QtObject connectingDevice;

    function connectDeviceAddress(btDeviceAddress)
    {
        var pendingCall;

        function __doConnect(device) {
            pendingCall = device.connectToDevice();
            pendingCall.finished.connect(function(call) {
                connectingDevice = null;
                if (call.error === 0)
                    _trustIfPaired(device);
            });
        }

        if (root.bluetoothOperational) {
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
                            _trustIfPaired(device);
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

    // The user picked this device and it is paired: let it connect back
    // (a headset switched on again) without the agent being asked.
    function _trustIfPaired(device)
    {
        if (Policy.shouldTrust(device)) {
            console.log("Marking", device.address, "trusted.");
            device.trusted = true;
        }
    }

    // Start a new search, for the "Search again" button.
    function searchAgain()
    {
        _discoveryTimedOut = false;
        discoveringMode = true;
        if (discovering)
            discoveryTimer.restart();
        _updateDiscovery();
    }

    function _updateDiscovery()
    {
        var adapter = btManager ? btManager.usableAdapter : null;
        var action = Policy.discoveryAction(discoveringMode, !!adapter,
                                            !!adapter && adapter.discovering === true,
                                            _discoveryTimedOut);
        if (action === "start") {
            console.log("Starting bluetooth discovery.");
            adapter.startDiscovery();
            discoveryTimer.restart();
        }
        else if (action === "stop") {
            console.log("Stopping bluetooth discovery.");
            adapter.stopDiscovery();
            discoveryTimer.stop();
        }
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
        id: discoveryTimer
        interval: root.discoveryTimeoutMs
        onTriggered: {
            root._discoveryTimedOut = true;
            root._updateDiscovery();
        }
    }

    /* Bindings to keep the discovering mode updated */
    Connections {
        target: btManager
        function onUsableAdapterChanged() {
            root._updateDiscovery();
        }
    }
    onDiscoveringModeChanged: {
        if (discoveringMode)
            _discoveryTimedOut = false;
        _updateDiscovery();
    }
    Component.onCompleted: _updateDiscovery()
    Component.onDestruction: {
        if(btManager.usableAdapter && btManager.usableAdapter.discovering) {
            console.log("Stopping bluetooth discovery.");
            btManager.usableAdapter.stopDiscovery();
        }
    }
}
