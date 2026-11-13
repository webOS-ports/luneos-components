/*
 * Copyright (C) 2017 Christophe Chapuis <chris.chapuis@gmail.com>
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

QtObject {
    id: agentId
    property string path: "/"
    property variant capability;

    // Whether bluetooth2 asks this agent the pairings devices start; a test
    // sets it false again for a subscription that went.
    property bool registered: false
    property int registerCalls: 0

    function registerToManager(btManager) {
        console.log("==> registerToManager()");
        registerCalls++;
        btManager.registerAgent(agentId);
        registered = true;
    }

    signal requestPinCodeFromUser(variant device, variant request);
    signal requestPasskeyFromUser(variant device, variant request);
    signal requestConfirmationFromUser(variant device, string passkey, variant request);
    signal requestAuthorizationFromUser(variant device, variant request);
    signal authorizeServiceFromUser(variant device, string uuid, variant request);
    signal displayPasskeyToUser(variant device, string passkey, string entered);
    signal displayPinCodeToUser(variant device, variant pinCode);
    signal cancel();
    signal release();
    signal pairingFailed(variant device, string reason);
}
