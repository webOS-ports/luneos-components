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
    property int capability;

    function registerToManager(btManager) {
        console.log("==> registerToManager()");
        btManager.registerAgent(agentId);
    }

    signal requestPinCodeFromUser(string device, variant request)
    signal requestPasskeyFromUser(string device, variant request)
    signal requestConfirmationFromUser(string device, string passkey, variant request)
    signal requestAuthorizationFromUser(string device, variant request)
    signal authorizeServiceFromUser(string device, string uuid, variant request)
    signal displayPasskey(string device, string passkey, string entered)
    signal displayPinCode(string device, variant pinCode)
    signal cancel()
    signal release()
}
