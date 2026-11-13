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
import LuneOS.Service 1.0
import LuneOS.System 1.0

import "BluetoothPolicy.js" as Policy

/*
 * Bluetooth for the shell and the apps, through com.webos.service.bluetooth2:
 * the adapter, its devices, searching, pairing and connecting. bluetooth2 is
 * the one owner of BlueZ on LuneOS - its agent answers pairings, it brings
 * the last headset back at power-on - so nothing here talks to BlueZ itself.
 *
 * The properties and functions are those the BluezQt-based module had, so
 * the shell and Settings work unchanged: connectDeviceAddress() and
 * disconnectDeviceAddress() return a call with finished(call) and error, and
 * btManager.deviceForAddress() still finds a device and its adapter.
 *
 * Power stays connman's: its Bluetooth technology is what airplane mode and
 * the user's switch set, and it keeps that across reboots.
 */
Item {
    id: root

    property alias powered: bluetoothTech.powered
    // The adapter bluetooth2 uses is up. Not BlueZ's rfkill view: some
    // devices carry a Bluetooth rfkill switch that never unblocks - on the
    // BlackBerry KEY2 (WCN3990) the vendor bt_power switch stays
    // soft-blocked because the chip has no enable GPIO, while the Android
    // HAL powers it through /dev/btpower.
    readonly property bool bluetoothOperational: _adapter !== null && _adapter.powered === true
    readonly property bool initializing: powered && !bluetoothOperational
    // Set while a device list is on screen. Discovery then runs for
    // discoveryTimeoutMs and stops; searchAgain() runs another.
    property bool discoveringMode: false
    property int discoveryTimeoutMs: Policy.discoveryTimeoutMs
    // The adapter is searching right now - for a "Searching..." indicator.
    readonly property bool discovering: bluetoothOperational && _adapter.discovering === true
    readonly property bool discoverable: bluetoothOperational && _adapter.discoverable === true
    // Some device is connected.
    readonly property bool connected: {
        for (var i = 0; i < _devices.length; i++) {
            if (Policy.deviceConnected(_devices[i]))
                return true;
        }
        return false;
    }
    // Set before _adapter, not bound to it: a handler of bluetoothOperationalChanged
    // (Settings registers its agent from one) has to find the address already,
    // where a binding on _adapter could still hold the old one.
    readonly property string adapterAddress: _adapterAddress
    // The devices the adapter knows, paired or found, as device/getStatus
    // gives them. BluetoothDevicesModel shows them.
    readonly property var devices: _devices

    // The device being paired or connected: {address, name}, or null.
    property var connectingDevice: null

    // What callers used of BluezQt's Manager.
    property QtObject btManager: QtObject {
        // {address, name, paired, trusted, connected, adapter: {address}}, or null.
        function deviceForAddress(address) {
            var device = Policy.findDevice(root._devices, address);
            if (!device)
                return null;
            return {
                "address": device.address,
                "name": device.name || "",
                "paired": device.paired === true,
                "trusted": device.trusted === true,
                "connected": Policy.deviceConnected(device),
                "adapter": {"address": root.adapterAddress}
            };
        }
    }

    // A pairing this manager started asks something of the user, or ended
    // (Policy.pairingPrompt). LuneOSBluetoothAgent shows it.
    signal pairingRequested(var prompt)

    property var _adapter: null
    property string _adapterAddress: ""
    property var _devices: []
    property var _adapterCall: null
    property var _devicesCall: null
    property var _pairCall: null
    property string _pairAddress: ""
    property QtObject _connectCall: null
    // This search has run its time; cleared by searchAgain() and by
    // discoveringMode being set again.
    property bool _discoveryTimedOut: false
    property bool _discoveryStarted: false

    property QtObject _bus: LunaService {
        name: Policy.clientName(Qt.application.name)
    }

    property QtObject _serviceStatus: ServiceStatus {
        serviceName: Policy.service
        clientName: Policy.clientName(Qt.application.name)
    }
    readonly property bool _serviceAvailable: _serviceStatus.available === true

    function connectDeviceAddress(btDeviceAddress)
    {
        if (!bluetoothOperational)
            return undefined;

        var device = Policy.findDevice(_devices, btDeviceAddress);
        var connecting = connectingDevice !== null && _sameAddress(connectingDevice.address, btDeviceAddress);
        if (connecting || Policy.deviceConnected(device))
            return disconnectDeviceAddress(btDeviceAddress);

        if (connectingDevice !== null)
            _abandonConnecting("Another device was picked");

        var call = _newCall();
        _connectCall = call;
        connectingDevice = {"address": btDeviceAddress, "name": device && device.name ? device.name : ""};
        if (device && device.paired === true)
            _connect(btDeviceAddress, call);
        else
            _pair(btDeviceAddress, call);
        return call;
    }

    function disconnectDeviceAddress(btDeviceAddress)
    {
        if (connectingDevice !== null && _sameAddress(connectingDevice.address, btDeviceAddress))
            _abandonConnecting("Disconnected");

        var call = _newCall();
        _bt("device/disconnect", {"address": btDeviceAddress}, function (reply) {
            call._finish(0, "");
        }, function (reply) {
            var failure = Policy.replyError(reply);
            call._finish(failure.error, failure.errorText);
        });
        return call;
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

    function setDiscoverable(isDiscoverable)
    {
        if (bluetoothOperational)
            _bt("adapter/setState", {"discoverable": isDiscoverable === true});
    }

    // A call to bluetooth2 on the adapter in use. onReply gets the parsed
    // reply when it says returnValue true, onFailure (if any) when it does
    // not or the call failed.
    // The arguments with the adapter in use, when one is known: bluetooth2
    // refuses an empty adapterAddress, and takes its default without one.
    function _withAdapter(args)
    {
        if (adapterAddress !== "" && args.adapterAddress === undefined)
            args.adapterAddress = adapterAddress;
        return args;
    }

    function _bt(method, args, onReply, onFailure)
    {
        var payload = {};
        for (var key in args)
            payload[key] = args[key];
        _withAdapter(payload);
        return _bus.call(Policy.uri + method, JSON.stringify(payload), function (message) {
            var reply = _parse(message);
            if (reply.returnValue === true) {
                if (onReply)
                    onReply(reply);
            } else {
                console.warn("Bluetooth: " + method + " failed: " + message.payload);
                if (onFailure)
                    onFailure(reply);
            }
        }, function (message) {
            console.warn("Bluetooth: " + method + " failed: " + (message ? message.payload : ""));
            if (onFailure)
                onFailure(_parse(message));
        });
    }

    function _parse(message)
    {
        try {
            return JSON.parse(message.payload) || {};
        } catch (e) {
            return {};
        }
    }

    function _sameAddress(a, b)
    {
        return String(a).toLowerCase() === String(b).toLowerCase();
    }

    function _newCall()
    {
        return pendingCallComponent.createObject(root);
    }

    function _pair(address, call)
    {
        _endPairing();
        _pairAddress = address;
        console.log("Pairing with", address);
        _pairCall = _bus.subscribe(Policy.uri + "adapter/pair",
                                   JSON.stringify(_withAdapter({"address": address, "subscribe": true})),
                                   function (message) {
            var reply = _parse(message);
            var prompt = Policy.pairingPrompt(reply, address);
            if (prompt !== null)
                root.pairingRequested(prompt);

            var outcome = Policy.pairOutcome(reply);
            if (outcome === "pending")
                return;
            _endPairing();
            if (call !== _connectCall)
                return;     // given up on meanwhile
            if (outcome === "paired") {
                console.log("Pairing has succeeded, connecting now...");
                _trust(address, true);
                _connect(address, call);
            } else {
                console.warn("Bluetooth: pairing with " + address + " failed: " + message.payload);
                _failConnecting(call, reply);
            }
        }, function (message) {
            _endPairing();
            if (call === _connectCall)
                _failConnecting(call, _parse(message));
        });
    }

    function _endPairing()
    {
        if (_pairCall) {
            _pairCall.cancel();
            _pairCall = null;
        }
        _pairAddress = "";
    }

    function _connect(address, call)
    {
        _bt("device/connect", {"address": address}, function (reply) {
            if (call !== _connectCall)
                return;
            _connectCall = null;
            connectingDevice = null;
            _trust(address, false);
            call._finish(0, "");
        }, function (reply) {
            if (call === _connectCall)
                _failConnecting(call, reply);
        });
    }

    function _failConnecting(call, reply)
    {
        if (call === _connectCall) {
            _connectCall = null;
            connectingDevice = null;
        }
        var failure = Policy.replyError(reply);
        call._finish(failure.error, failure.errorText);
    }

    // The user gave up on the device being connected, or picked another.
    function _abandonConnecting(reason)
    {
        var call = _connectCall;
        var address = connectingDevice ? connectingDevice.address : "";
        _connectCall = null;
        connectingDevice = null;
        if (_pairAddress !== "" && _sameAddress(_pairAddress, address))
            _bt("adapter/cancelPairing", {"address": address});
        _endPairing();
        if (call)
            call._finish(1, reason);
    }

    // The user picked this device and it is paired: let it connect back
    // (a headset switched on again) without the agent being asked.
    // justPaired: the device list may not say "paired" yet.
    function _trust(address, justPaired)
    {
        var device = Policy.findDevice(_devices, address);
        var state = {"paired": justPaired || (device !== null && device.paired === true),
                     "trusted": device !== null && device.trusted === true};
        if (Policy.shouldTrust(state)) {
            console.log("Marking", address, "trusted.");
            _bt("device/setState", {"address": address, "trusted": true});
        }
    }

    function _updateDiscovery()
    {
        var action = Policy.discoveryAction(discoveringMode && connectingDevice === null,
                                            bluetoothOperational, discovering, _discoveryTimedOut);
        if (action === "start") {
            console.log("Starting bluetooth discovery.");
            _discoveryStarted = true;
            _bt("adapter/startDiscovery", {});
            discoveryTimer.restart();
        }
        else if (action === "stop") {
            console.log("Stopping bluetooth discovery.");
            _discoveryStarted = false;
            _bt("adapter/cancelDiscovery", {});
            discoveryTimer.stop();
        }
    }

    function _watchService()
    {
        _unwatchService();
        if (!_serviceAvailable)
            return;
        _adapterCall = _bus.subscribe(Policy.uri + "adapter/getStatus", JSON.stringify({"subscribe": true}),
                                      function (message) {
            var reply = _parse(message);
            if (reply.returnValue === false) {
                console.warn("Bluetooth: adapter/getStatus failed: " + message.payload);
                return;
            }
            if (reply.adapters !== undefined)
                _setAdapter(Policy.pickAdapter(reply.adapters));
        }, function (message) {
            console.warn("Bluetooth: cannot watch the adapter: " + (message ? message.payload : ""));
        });
    }

    function _unwatchService()
    {
        if (_adapterCall) {
            _adapterCall.cancel();
            _adapterCall = null;
        }
        _unwatchDevices();
        _setAdapter(null);
    }

    function _setAdapter(adapter)
    {
        _adapterAddress = adapter && adapter.adapterAddress ? String(adapter.adapterAddress) : "";
        _adapter = adapter;
    }

    // The devices of the adapter in use; again whenever that changes.
    function _watchDevices()
    {
        _unwatchDevices();
        if (adapterAddress === "")
            return;
        _devicesCall = _bus.subscribe(Policy.uri + "device/getStatus",
                                      JSON.stringify({"subscribe": true, "adapterAddress": adapterAddress}),
                                      function (message) {
            var reply = _parse(message);
            if (reply.returnValue === false) {
                console.warn("Bluetooth: device/getStatus failed: " + message.payload);
                return;
            }
            if (reply.devices !== undefined)
                _devices = reply.devices;
        }, function (message) {
            console.warn("Bluetooth: cannot watch the devices: " + (message ? message.payload : ""));
        });
    }

    function _unwatchDevices()
    {
        if (_devicesCall) {
            _devicesCall.cancel();
            _devicesCall = null;
        }
        if (_devices.length > 0)
            _devices = [];
    }

    Component {
        id: pendingCallComponent
        BluetoothPendingCall { }
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

    on_ServiceAvailableChanged: _watchService()
    onAdapterAddressChanged: _watchDevices()
    onBluetoothOperationalChanged: {
        // The adapter went: so did whatever was being connected on it.
        if (!bluetoothOperational && _connectCall)
            _failConnecting(_connectCall, {"errorText": "Bluetooth was switched off"});
        _updateDiscovery();
    }
    onConnectingDeviceChanged: _updateDiscovery()
    onDiscoveringModeChanged: {
        if (discoveringMode)
            _discoveryTimedOut = false;
        _updateDiscovery();
    }
    Component.onCompleted: {
        _watchService();
        _updateDiscovery();
    }
    Component.onDestruction: {
        if (_discoveryStarted && discovering) {
            console.log("Stopping bluetooth discovery.");
            _bt("adapter/cancelDiscovery", {});
        }
        _endPairing();
        _unwatchService();
    }
}
