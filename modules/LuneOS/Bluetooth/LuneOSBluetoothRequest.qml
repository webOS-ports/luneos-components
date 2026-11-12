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

/*
 * A question a pairing asks the user, from LuneOSBluetoothAgent: answer it
 * once with accept() (with the passkey or PIN when one was asked for),
 * reject() or cancel(). What comes after the first answer is ignored, as is
 * an answer to a pairing that is over by then.
 *
 * The answer goes to com.webos.service.bluetooth2: a passkey confirmation or
 * a pairing to allow is said yes or no to (supplyPasskeyConfirmation), a
 * passkey or PIN is supplied or the pairing cancelled.
 */
QtObject {
    id: request

    // "confirmation", "authorization", "passkey" or "pinCode" (Policy.pairingPrompt)
    property string kind: ""
    property string address: ""
    property string adapterAddress: ""
    property QtObject manager: null

    readonly property bool answered: _answered
    property bool _answered: false

    function accept(returnValue) {
        if (!_take())
            return;
        if (kind === "confirmation" || kind === "authorization")
            _send("adapter/supplyPasskeyConfirmation", {"accept": true});
        else if (kind === "passkey")
            _send("adapter/supplyPasskey", {"passkey": parseInt(returnValue, 10) || 0});
        else if (kind === "pinCode")
            _send("adapter/supplyPinCode", {"pin": returnValue === undefined || returnValue === null ? "" : String(returnValue)});
    }

    function reject() {
        if (_take())
            _refuse();
    }

    function cancel() {
        if (_take())
            _refuse();
    }

    function _refuse() {
        if (kind === "confirmation" || kind === "authorization")
            _send("adapter/supplyPasskeyConfirmation", {"accept": false});
        else
            _send("adapter/cancelPairing", {});
    }

    function _take() {
        if (_answered)
            return false;
        _answered = true;
        return true;
    }

    // The pairing ended, or another question took this one's place: there
    // is nothing left to answer.
    function _drop() {
        _answered = true;
    }

    function _send(method, args) {
        if (!manager)
            return;
        args.address = address;
        if (adapterAddress !== "")
            args.adapterAddress = adapterAddress;
        manager._bt(method, args);
    }
}
