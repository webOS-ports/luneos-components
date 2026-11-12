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

// The decisions LuneOS.Bluetooth takes, and how it reads what
// com.webos.service.bluetooth2 answers, kept apart so they can be tested
// without the service.

.pragma library

var service = "com.webos.service.bluetooth2";
var uri = "luna://" + service + "/";

// How long one search runs before it stops by itself. A BR/EDR inquiry
// takes 10.24 s, so this is three of them; a headset in pairing mode turns
// up within the first. Searching any longer costs battery, and an inquiry
// running next to an A2DP stream makes the music stutter.
var discoveryTimeoutMs = 30000;

/**
 * The name to call bluetooth2 as. An app's own ID (empty: LunaService takes
 * the application's name, which qml-runner sets to the app ID). The shell
 * process is "surface-manager", which its role does not allow on the bus; it
 * calls under the name its own QML uses for bluetooth2 already.
 */
function clientName(applicationName) {
    return applicationName === "surface-manager" ? "com.webos.surfacemanager.cardshell" : "";
}

/**
 * What to do with the adapter's discovery: "start", "stop" or "none".
 *
 * wanted      - someone shows the device list (BluetoothManager.discoveringMode),
 *               and no pairing or connect is under way (bluetooth2 refuses to
 *               pair while the adapter discovers)
 * hasAdapter  - bluetooth2 has a powered adapter
 * discovering - the adapter is discovering now
 * timedOut    - this search has run for discoveryTimeoutMs
 */
function discoveryAction(wanted, hasAdapter, discovering, timedOut) {
    if (!hasAdapter)
        return "none";

    var run = wanted && !timedOut;
    if (run && !discovering)
        return "start";
    if (!run && discovering)
        return "stop";
    return "none";
}

/**
 * Whether to mark a device trusted. The user picked it in the list and it
 * is paired now, so BlueZ should let it connect back - a headset
 * reconnecting after it was switched off - without asking the agent, as
 * GNOME and Plasma do after pairing.
 */
function shouldTrust(device) {
    return !!device && device.paired === true && device.trusted !== true;
}

/** The adapter to use from adapter/getStatus's "adapters": the first, as bluetooth2's default. */
function pickAdapter(adapters) {
    if (!adapters || adapters.length === 0)
        return null;
    return adapters[0];
}

/**
 * Whether a device from device/getStatus is connected: its link is up
 * ("connected", which LuneOS's bluetooth2 adds), or, from a bluetooth2
 * without it, one of its profiles is.
 */
function deviceConnected(device) {
    if (!device)
        return false;
    if (device.connected !== undefined)
        return device.connected === true;
    return !!device.connectedProfiles && device.connectedProfiles.length > 0;
}

/** The device with this address from a device/getStatus list, or null. */
function findDevice(devices, address) {
    if (!devices || !address)
        return null;
    var wanted = String(address).toLowerCase();
    for (var i = 0; i < devices.length; i++) {
        if (devices[i] && String(devices[i].address).toLowerCase() === wanted)
            return devices[i];
    }
    return null;
}

/*
 * BluetoothDevicesModel's roles, by the names and numbers KDE's BluezQt
 * DevicesModel gave them (Qt::UserRole + n), so that QML written against it -
 * a delegate's model.Name, a filterRole of 256 + 109 for "Paired" - keeps
 * working. Only those bluetooth2 can fill are here; every row has each of
 * them, with the same type, as ListModel wants.
 */
var roles = {
    "Address": 256 + 101,
    "Name": 256 + 102,
    "FriendlyName": 256 + 103,
    "RemoteName": 256 + 104,
    "Class": 256 + 105,
    "Paired": 256 + 109,
    "Trusted": 256 + 110,
    "Blocked": 256 + 111,
    "Rssi": 256 + 113,
    "Connected": 256 + 114,
    "AdapterAddress": 256 + 118
};

/** A BluetoothDevicesModel row for a device from device/getStatus. */
function deviceRow(device) {
    var name = device.name ? String(device.name) : "";
    return {
        "Address": String(device.address || ""),
        "Name": name,
        "FriendlyName": name,
        "RemoteName": name,
        "Class": Number(device.classOfDevice) || 0,
        "Paired": device.paired === true,
        "Trusted": device.trusted === true,
        "Blocked": device.blocked === true,
        "Rssi": Number(device.rssi) || 0,
        "Connected": deviceConnected(device),
        "AdapterAddress": String(device.adapterAddress || "")
    };
}

/** The role name for a BluezQt role number, or "" for one not offered. */
function roleName(number) {
    for (var name in roles) {
        if (roles[name] === number)
            return name;
    }
    return "";
}

/**
 * Whether a row passes the model's filter, as QSortFilterProxyModel's
 * filterRole and filterRegularExpression did: the role's value, as text,
 * matches the expression. No role or no expression: every row.
 */
function rowMatches(row, filterRole, filterRegularExpression) {
    if (!filterRole || !filterRegularExpression)
        return true;
    var name = roleName(filterRole);
    if (name === "")
        return true;
    var expression = filterRegularExpression instanceof RegExp
        ? filterRegularExpression : new RegExp(String(filterRegularExpression));
    return expression.test(String(row[name]));
}

/**
 * Brings a ListModel's rows in line with devices (a device/getStatus list,
 * filtered): a row that is there already is updated in place, a device that
 * is new goes to the end, a row whose device went is removed. Rows keep their
 * place, so a list on screen does not jump about as devices turn up.
 */
function syncRows(model, devices, filterRole, filterRegularExpression) {
    var wanted = [];
    var byAddress = {};
    var count = devices ? devices.length : 0;
    for (var i = 0; i < count; i++) {
        if (!devices[i] || !devices[i].address)
            continue;
        var row = deviceRow(devices[i]);
        if (!rowMatches(row, filterRole, filterRegularExpression))
            continue;
        var key = row.Address.toLowerCase();
        if (byAddress[key])
            continue;
        byAddress[key] = row;
        wanted.push(key);
    }

    for (var r = model.count - 1; r >= 0; r--) {
        if (!byAddress[String(model.get(r).Address).toLowerCase()])
            model.remove(r);
    }

    var present = {};
    for (r = 0; r < model.count; r++) {
        var current = model.get(r);
        var address = String(current.Address).toLowerCase();
        present[address] = true;
        var update = byAddress[address];
        for (var role in update) {
            if (current[role] !== update[role])
                model.setProperty(r, role, update[role]);
        }
    }

    for (i = 0; i < wanted.length; i++) {
        if (!present[wanted[i]])
            model.append(byAddress[wanted[i]]);
    }
}

/** A passkey as the user compares it: six digits, leading zeros kept. */
function passkeyText(passkey) {
    var text = String(Number(passkey) || 0);
    while (text.length < 6)
        text = "0" + text;
    return text;
}

/**
 * What a pairing reply from bluetooth2 (on adapter/pair or
 * adapter/awaitPairingRequests) asks of the user, or null for nothing:
 *   {kind, address, name, passkey, pin, adapterAddress}
 * kind is one of "confirmation" (compare a passkey), "authorization" (allow
 * a pairing with nothing to compare), "passkey" or "pinCode" (type one in),
 * "displayPasskey" or "displayPinCode" (show one, to type in on the device),
 * or "end" (the pairing is over, done or not: the open question goes).
 * fallbackAddress is the device an adapter/pair subscription is for, as
 * bluetooth2 leaves the address out of some of its messages there.
 */
function pairingPrompt(reply, fallbackAddress) {
    if (!reply || !reply.request)
        return null;
    var prompt = {
        "kind": "",
        "address": String(reply.address || fallbackAddress || ""),
        "name": String(reply.name || ""),
        "passkey": "",
        "pin": "",
        "adapterAddress": String(reply.adapterAddress || "")
    };
    switch (reply.request) {
    case "confirmPasskey":
        prompt.kind = "confirmation";
        prompt.passkey = passkeyText(reply.passkey);
        break;
    case "authorizePairing":
        prompt.kind = "authorization";
        break;
    case "enterPasskey":
        prompt.kind = "passkey";
        break;
    case "enterPinCode":
        prompt.kind = "pinCode";
        break;
    case "displayPasskey":
        prompt.kind = "displayPasskey";
        prompt.passkey = passkeyText(reply.passkey);
        break;
    case "displayPinCode":
        prompt.kind = "displayPinCode";
        prompt.pin = String(reply.pin || "");
        break;
    case "endPairing":
        prompt.kind = "end";
        break;
    default:
        return null;
    }
    return prompt;
}

/**
 * Where an adapter/pair subscription is: "pending" (asked, or asking the
 * user), "paired" or "failed". bluetooth2 answers the call at once, asks
 * through the same subscription, and ends it with "endPairing"; a refusal
 * up front (a pairing already under way, the device gone) is a plain error.
 */
function pairOutcome(reply) {
    if (!reply)
        return "failed";
    if (reply.request === "endPairing")
        return reply.returnValue === true ? "paired" : "failed";
    if (reply.returnValue === false)
        return "failed";
    return "pending";
}

/** The error code and text of a failed bluetooth2 reply; the code is never 0. */
function replyError(reply) {
    var code = reply && reply.errorCode ? Number(reply.errorCode) : 0;
    return {
        "error": code !== 0 ? code : 1,
        "errorText": reply && reply.errorText ? String(reply.errorText) : "Bluetooth request failed"
    };
}
