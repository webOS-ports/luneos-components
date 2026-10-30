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

// The decisions BluetoothManager takes, kept apart so they can be tested
// without BlueZ.

.pragma library

// How long one search runs before it stops by itself. A BR/EDR inquiry
// takes 10.24 s, so this is three of them; a headset in pairing mode turns
// up within the first. Searching any longer costs battery, and an inquiry
// running next to an A2DP stream makes the music stutter.
var discoveryTimeoutMs = 30000;

/**
 * What to do with the adapter's discovery: "start", "stop" or "none".
 *
 * wanted      - someone shows the device list (BluetoothManager.discoveringMode)
 * hasAdapter  - BluezQt offers a usable adapter
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
