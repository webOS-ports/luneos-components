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

    // A refused registration is tried again this often, this many times in
    // a row, while Bluetooth stays up: right after bluetoothd restarts,
    // bluetooth2 has the adapter back before it can make it pairable, and
    // refuses (123). Nothing else would register again, since Bluetooth
    // did not go down as the page sees it.
    property int retryIntervalMs: 2000
    property int retries: 5

    property var _incoming: null
    property int _retried: 0
    property QtObject _open: null
    property bool _showing: false

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
            "manager": manager
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
        function onBluetoothOperationalChanged() {
            // Its subscription went with the adapter.
            if (!agent.manager.bluetoothOperational) {
                agent._retryTimer.stop();
                agent._retried = 0;
                agent._unregister();
                agent._show({"kind": "end"});
            }
        }
    }

    Component.onDestruction: {
        _retryTimer.stop();
        // An open question goes unanswered with the page: refuse it rather
        // than leave the device waiting.
        if (_open !== null && !_open.answered)
            _open.cancel();
        _unregister();
    }
}
