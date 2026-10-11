/*
 * (c) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import LuneOS.Service 1.0

import "Services.js" as Services

/*
 * Whether a service is on the bus, and when that changes.
 *
 *     ServiceStatus {
 *         id: torch
 *         serviceName: "org.webosports.service.torch"
 *         onAvailableChanged: if (available) subscribeToIt()
 *     }
 *
 * "known" turns true with the bus's first answer, so a page can tell "not
 * there" from "not asked yet" and not flash an unavailable notice while it
 * starts. A service that is not installed on a device (torchd, say) simply
 * stays unavailable instead of failing a call once at startup and never
 * trying again - which is what the shell, Camera, Settings, Remote and Torch
 * each wrote by hand.
 *
 * Asking the bus needs no ACG group of its own: on the Q25 it answered
 * Remote, whose only group is ir.operation.
 */
QtObject {
    id: status

    property string serviceName: ""
    // The name to call the bus as. Empty means the application's own, which
    // is right for an app; the shell passes its own service name.
    property alias clientName: bus.name

    readonly property bool available: _available
    readonly property bool known: _known

    property bool _available: false
    property bool _known: false
    property var _call: null
    property bool _ready: false

    onServiceNameChanged: _watch()

    function _watch() {
        if (!_ready)
            return;
        if (_call) {
            _call.cancel();
            _call = null;
        }
        _known = false;
        _available = false;
        if (serviceName === "")
            return;
        _call = bus.subscribe(Services.bus + "/signal/registerServerStatus",
                              JSON.stringify({ "serviceName": serviceName }),
                              function (message) {
                                  var response = JSON.parse(message.payload);
                                  if (response.connected === undefined)
                                      return;
                                  status._available = response.connected === true;
                                  status._known = true;
                              },
                              function (message) {
                                  console.warn("ServiceStatus: cannot watch " + status.serviceName
                                               + ": " + message.payload);
                              });
    }

    property LunaService _bus: LunaService {
        id: bus
        onInitialized: {
            status._ready = true;
            status._watch();
        }
    }
}
