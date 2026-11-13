/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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

import "BluetoothPolicy.js" as Policy

/*
 * What a pairing asks the user, as signals for a page to show: a passkey to
 * compare, a pairing to allow, a passkey or PIN to type or to show. Each
 * question comes with a LuneOSBluetoothRequest to answer it; cancel() says
 * the pairing ended, and whatever is on screen for it should go.
 *
 * The questions are those of com.webos.service.bluetooth2, whose agent BlueZ
 * asks - this is no BlueZ agent of its own:
 *  - for a pairing BluetoothManager started (the user picked a device), from
 *    its adapter/pair subscription, always;
 *  - for one a device starts, from adapter/awaitPairingRequests, once
 *    registerToManager() has subscribed to it. bluetooth2 takes one such
 *    subscriber, and while there is none it refuses those pairings, and the
 *    adapter is not pairable. So a page that lets devices pair registers
 *    while it is up, and the subscription ends with the agent.
 *
 * capability and path are kept for QML written for the BluezQt agent: the
 * capability is bluetooth2's, set for the image (DisplayYesNo on LuneOS).
 * authorizeServiceFromUser is never emitted: bluetooth2 decides those.
 */
QtObject {
    id: agent

    enum Capability {
        DisplayOnly,
        DisplayYesNo,
        KeyboardOnly,
        NoInputNoOutput
    }

    property int capability: 3
    property string path: "/"
    // Stand-in in the tests.
    property QtObject manager: BluetoothManager

    readonly property bool registered: _incoming !== null

    signal displayPinCodeToUser(var device, string pinCode)
    signal displayPasskeyToUser(var device, string passkey, string entered)
    signal requestPinCodeFromUser(var device, var request)
    signal requestPasskeyFromUser(var device, var request)
    signal requestConfirmationFromUser(var device, string passkey, var request)
    signal requestAuthorizationFromUser(var device, var request)
    signal authorizeServiceFromUser(var device, string uuid, var request)
    signal cancel()
    signal release()
    // A pairing ended without the device paired, and not because the user
    // said no: for the page to say so. reason is bluetooth2's, or the
    // agent's own when bluetooth2 says nothing - it does not tell how a
    // pairing a device started went once it is answered (a wrong PIN), so
    // the device is watched: paired, fine; its connection gone or not
    // paired within pairingTimeoutMs, failed.
    signal pairingFailed(var device, string reason)

    // A refused registration is tried again this often, this many times in
    // a row, while Bluetooth stays up: right after bluetoothd restarts,
    // bluetooth2 has the adapter back before it can make it pairable, and
    // refuses (123). Nothing else would register again, since Bluetooth
    // did not go down as the page sees it.
    property int retryIntervalMs: 2000
    property int retries: 5
    property int pairingTimeoutMs: 30000

    property var _incoming: null
    property int _retried: 0
    property QtObject _open: null
    property bool _showing: false
    // The device of the question a device's pairing asked last, till it ends.
    property var _incomingDevice: null
    // A device's pairing the user said yes to, not paired yet.
    property var _waitingDevice: null
    property bool _sawConnected: false

    // Pairings devices start are asked here too, from now on. Again after
    // Bluetooth came back on; doing it twice is harmless.
    function registerToManager(btManager) {
        if (_incoming !== null || !manager || !manager.bluetoothOperational)
            return;
        _incoming = manager._bus.subscribe(Policy.uri + "adapter/awaitPairingRequests",
                                           JSON.stringify(manager._withAdapter({"subscribe": true})),
                                           function (message) {
            var reply = manager._parse(message);
            if (reply.returnValue === true && reply.subscribed === true && reply.request === undefined)
                _retried = 0;   // registered
            var prompt = Policy.pairingPrompt(reply, "");
            if (prompt !== null) {
                _incomingAsks(prompt, reply);
                _show(prompt);
                return;
            }
            // Refused (another subscriber, Bluetooth gone) or ended by the
            // service (the adapter's pairable time ran out): register again
            // next time.
            if (reply.returnValue === false || reply.subscribed === false) {
                console.warn("Bluetooth: no longer asked for pairings devices start: " + message.payload);
                _unregister();
                // Not when another client has it (104): it keeps it.
                if (Number(reply.errorCode) !== 104)
                    _retryLater();
            }
        }, function (message) {
            console.warn("Bluetooth: cannot wait for pairing requests: " + (message ? message.payload : ""));
            _unregister();
            _retryLater();
        });
    }

    // A device's pairing asks, or ended; bluetooth2 ends it with an error
    // when it was cancelled or nobody answered in time.
    function _incomingAsks(prompt, reply) {
        if (prompt.kind !== "end") {
            _stopWaiting();
            manager._userRefused("");
            _incomingDevice = _deviceFor(prompt);
            return;
        }
        var device = _incomingDevice;
        _incomingDevice = null;
        if (device === null || reply.returnValue !== false)
            return;
        _stopWaiting();
        if (!manager._refusedBy(device.address))
            _failed(device, Policy.replyError(reply).errorText);
    }

    // LuneOSBluetoothRequest: the user said yes. To a pairing the manager
    // started, its adapter/pair says how it went; to one a device started,
    // nothing does.
    function _answered(request) {
        if (!manager || (manager._pairAddress !== "" && manager._sameAddress(manager._pairAddress, request.address)))
            return;
        _waitingDevice = _deviceFor({"name": "", "address": request.address});
        _sawConnected = false;
        _pairingTimer.restart();
        _checkWaiting();
    }

    function _checkWaiting() {
        if (_waitingDevice === null || !manager)
            return;
        var device = Policy.findDevice(manager._devices, _waitingDevice.address);
        if (device && device.paired === true)
            _stopWaiting();
        else if (device && device.connected === true)
            _sawConnected = true;
        else if (_sawConnected)
            _failWaiting("The device disconnected before it was paired");
    }

    function _stopWaiting() {
        _waitingDevice = null;
        _pairingTimer.stop();
    }

    function _failWaiting(reason) {
        var device = _waitingDevice;
        _stopWaiting();
        if (device !== null)
            _failed(device, reason);
    }

    function _failed(device, reason) {
        console.warn("Bluetooth: pairing with " + device.name + " (" + device.address + ") failed: " + reason);
        pairingFailed(device, reason);
    }

    property Timer _pairingTimer: Timer {
        interval: agent.pairingTimeoutMs
        onTriggered: agent._failWaiting("The device was not paired in time")
    }

    function _retryLater() {
        if (!manager || !manager.bluetoothOperational || _retried >= retries)
            return;
        _retried++;
        _retryTimer.restart();
    }

    property Timer _retryTimer: Timer {
        interval: agent.retryIntervalMs
        onTriggered: agent.registerToManager(agent.manager ? agent.manager.btManager : null)
    }

    function _unregister() {
        if (_incoming !== null) {
            _incoming.cancel();
            _incoming = null;
        }
    }

    function _deviceFor(prompt) {
        var name = prompt.name;
        if (name === "" && manager && manager.btManager) {
            const known = manager.btManager.deviceForAddress(prompt.address);
            if (known)
                name = known.name;
        }
        return {"name": name !== "" ? name : prompt.address, "address": prompt.address};
    }

    function _newRequest(prompt) {
        _dropOpen();
        _open = requestComponent.createObject(agent, {
            "kind": prompt.kind,
            "address": prompt.address,
            "adapterAddress": prompt.adapterAddress,
            "manager": manager,
            "agent": agent
        });
        return _open;
    }

    function _dropOpen() {
        // Not destroyed: the popup asking it still holds it, and cancels it
        // as it closes - which a dropped request ignores.
        if (_open !== null) {
            _open._drop();
            _open = null;
        }
    }

    function _show(prompt) {
        if (prompt.kind === "end") {
            _dropOpen();
            if (_showing) {
                _showing = false;
                cancel();
            }
            return;
        }

        var device = _deviceFor(prompt);
        _showing = true;
        switch (prompt.kind) {
        case "confirmation":
            requestConfirmationFromUser(device, prompt.passkey, _newRequest(prompt));
            break;
        case "authorization":
            requestAuthorizationFromUser(device, _newRequest(prompt));
            break;
        case "passkey":
            requestPasskeyFromUser(device, _newRequest(prompt));
            break;
        case "pinCode":
            requestPinCodeFromUser(device, _newRequest(prompt));
            break;
        case "displayPasskey":
            _dropOpen();
            displayPasskeyToUser(device, prompt.passkey, "");
            break;
        case "displayPinCode":
            _dropOpen();
            displayPinCodeToUser(device, prompt.pin);
            break;
        }
    }

    property Component _requestComponent: Component {
        id: requestComponent
        LuneOSBluetoothRequest { }
    }

    property Connections _pairings: Connections {
        target: agent.manager
        function onPairingRequested(prompt) {
            agent._show(prompt);
        }
        function onPairingFailed(address, reason) {
            agent._failed(agent._deviceFor({"name": "", "address": address}), reason);
        }
        function onDevicesChanged() {
            agent._checkWaiting();
        }
        function onBluetoothOperationalChanged() {
            // Its subscription went with the adapter.
            if (!agent.manager.bluetoothOperational) {
                agent._retryTimer.stop();
                agent._retried = 0;
                agent._unregister();
                agent._stopWaiting();
                agent._incomingDevice = null;
                agent._show({"kind": "end"});
            }
        }
    }

    Component.onDestruction: {
        _retryTimer.stop();
        _pairingTimer.stop();
        // An open question goes unanswered with the page: refuse it rather
        // than leave the device waiting.
        if (_open !== null && !_open.answered)
            _open.cancel();
        _unregister();
    }
}
