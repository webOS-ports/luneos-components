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
 * What BluetoothManager's connect and disconnect return: finished(call) once
 * the request is done, with error 0 when it worked, as BluezQt's
 * PendingCall did - callers written against that keep working.
 */
QtObject {
    id: call

    signal finished(var call)

    property int error: 0
    property string errorText: ""
    readonly property bool isFinished: _finished

    property bool _finished: false

    function _finish(errorCode, text) {
        if (_finished)
            return;
        error = errorCode;
        errorText = text || "";
        _finished = true;
        finished(call);
        // Left to the caller's handlers for a moment, then gone.
        call.destroy(1000);
    }
}
