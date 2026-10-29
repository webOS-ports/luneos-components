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

/*
 * The screen kept on - no dimming, no timeout - while active: a video
 * playing, a slideshow running. luna-displaymanager's "requestBlock" holds
 * the display for as long as the call stays open; cancelling it lets go.
 * The app needs "display.operation".
 *
 *   KeepScreenOn {
 *       clientName: "org.webosports.app.photos"
 *       active: appWindow.active && player.playing
 *   }
 *
 * subscribe, when set, is the app's own bus call (function(uri, json,
 * onReply, onError) returning the call); else the object's LunaService.
 */
QtObject {
    id: keep

    property bool active: false
    // The name the display manager is told, and the LunaService's
    property string clientName: ""
    property var subscribe: null
    readonly property bool blocked: _call !== null

    property var _call: null

    onActiveChanged: _update()
    Component.onCompleted: _update()
    Component.onDestruction: { active = false; _update(); }

    function _update() {
        if (active && !_call) {
            var uri = "luna://com.palm.display/control/setProperty";
            var json = JSON.stringify({ "requestBlock": true, "client": clientName });
            var failed = function(error) { console.warn("KeepScreenOn: could not keep the screen on: " + error); };
            var call = keep.subscribe ? keep.subscribe(uri, json, function() {}, failed)
                                      : keep._service.subscribe(uri, json, function() {}, failed);
            // A stand-in for the bus may give no call back
            _call = call || ({});
        } else if (!active && _call) {
            if (typeof _call.cancel === "function")
                _call.cancel();
            _call = null;
        }
    }

    property LunaService _service: LunaService {
        name: keep.clientName
    }
}
