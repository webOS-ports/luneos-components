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
    id: luneosRequest
    property int requestType: 0 // 0=void, 1=uint32, 2=string

    // As the plugin's LuneOSBluetoothRequest: slots, the value optional, and
    // only the first answer counts. These were signals, so a page calling
    // accept() with no value threw "Insufficient arguments" here although it
    // works on a device. The signals below are for tests to watch.
    readonly property bool answered: _answered
    property bool _answered: false

    signal accepted(variant returnValue)
    signal rejected()
    signal canceled()

    function _markAnswered() {
        if (_answered)
            return false;
        _answered = true;
        return true;
    }
    function accept(returnValue) {
        if (!_markAnswered())
            return;
        console.log("bluetooth request accepted (value=" + returnValue + ").");
        accepted(returnValue);
    }
    function reject() {
        if (!_markAnswered())
            return;
        console.log("bluetooth request rejected.");
        rejected();
    }
    function cancel() {
        if (!_markAnswered())
            return;
        console.log("bluetooth request canceled.");
        canceled();
    }
}
