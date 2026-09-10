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

.pragma library

/*
 * A stand-in for storaged's diskmode category (com.palm.storage).
 *
 * Note "result" and not "returnValue": that is the spelling diskmode has
 * answered with since Open webOS, and a stub that quietly used the usual one
 * would let a page pass here and fail on a device.
 *
 * No cable is plugged in, which is the state a desktop is in.
 */
var hostConnected = false;
var inMSM = false;

function hostIsConnectedPayload() {
    return { "result": true, "hostIsConnected": hostConnected };
}

function queryMSMStatusPayload() {
    return { "result": true, "inMSM": inMSM };
}

function setHostConnected(connected) {
    hostConnected = connected;
    if (!connected)
        inMSM = false;
}

function enterMSM(args) {
    // The real one checks for a connected host first and does nothing quietly
    // when there is none, while still answering result: true.
    if (args["user-confirmed"] === true && hostConnected)
        inMSM = true;

    return { "result": true };
}
