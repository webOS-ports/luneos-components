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
 * The system service's preferences: read, kept up to date, and written.
 *
 *     SystemPreferences {
 *         id: prefs
 *         keys: ["timeFormat", "rotationLock"]
 *     }
 *     Label { text: prefs.values.timeFormat === "HH24" ? "24 hour" : "12 hour" }
 *     Switch { onToggled: prefs.set("rotationLock", checked ? 0 : 400) }
 *
 * "values" holds the latest answer for each key and is replaced as a whole,
 * so bindings to it follow every change. changed() fires per key; updated()
 * once per answer with the answer as it came, for a page that maps several
 * keys at once. A write before the first read is
 * refused: a page that sets a default from its own state while the real
 * value is still on its way would otherwise overwrite the user's setting -
 * the guard the shell's own Preferences.qml keeps.
 *
 * Reading needs the "systemsettings.query" ACG group and writing
 * "systemsettings.management" (Remote, which has neither, was refused
 * getPreferences on the Q25); a refusal arrives as error().
 *
 * A subscription ends when the system service goes off the bus, and a
 * restarted service knows nothing of the old ones: the shell kept showing
 * the old wallpaper after luna-sysservice was restarted on tissot, as no
 * change reached it any more. So the service is watched, and when it is
 * back the keys are subscribed to afresh; the first answer brings anything
 * that changed meanwhile. Writes are refused again until it has come.
 */
QtObject {
    id: prefs

    property var keys: []
    // The name to call the service as. Empty means the application's own.
    property alias clientName: service.name

    readonly property var values: _values
    readonly property bool loaded: _loaded

    signal changed(string key, var value)
    signal updated(var response)
    signal error(string message)

    property var _values: ({})
    property bool _loaded: false
    property var _call: null
    property bool _ready: false
    // The system service went off the bus since the last subscription
    property bool _lost: false

    onKeysChanged: _subscribe()

    function value(key, fallback) {
        return _values.hasOwnProperty(key) ? _values[key] : fallback;
    }

    // Writes one preference. Returns false, and writes nothing, until the
    // first read has arrived.
    function set(key, value) {
        var change = {};
        change[key] = value;
        return setMany(change);
    }

    function setMany(change) {
        if (!_loaded) {
            console.warn("SystemPreferences: not writing " + Object.keys(change).join(", ")
                         + " before the first read");
            return false;
        }
        service.call(Services.systemService + "/setPreferences", JSON.stringify(change),
                     function (message) {
                         var response = JSON.parse(message.payload);
                         if (response.returnValue === false)
                             prefs.error(response.errorText || "setPreferences failed");
                     },
                     function (message) { prefs.error(typeof message === "string" ? message : message.payload); });
        return true;
    }

    function _subscribe() {
        if (!_ready)
            return;
        if (_call) {
            _call.cancel();
            _call = null;
        }
        _loaded = false;
        if (!keys || keys.length === 0)
            return;
        _call = service.subscribe(Services.systemService + "/getPreferences",
                                  JSON.stringify({ "keys": keys, "subscribe": true }),
                                  function (message) {
                                      var response = JSON.parse(message.payload);
                                      if (response.returnValue === false) {
                                          prefs.error(response.errorText || "getPreferences failed");
                                          return;
                                      }
                                      var next = {};
                                      for (var k in prefs._values)
                                          next[k] = prefs._values[k];
                                      var changedKeys = [];
                                      for (var i = 0; i < prefs.keys.length; i++) {
                                          var key = prefs.keys[i];
                                          if (response.hasOwnProperty(key)) {
                                              next[key] = response[key];
                                              changedKeys.push(key);
                                          }
                                      }
                                      prefs._values = next;
                                      prefs._loaded = true;
                                      for (var j = 0; j < changedKeys.length; j++)
                                          prefs.changed(changedKeys[j], next[changedKeys[j]]);
                                      prefs.updated(response);
                                  },
                                  function (message) { prefs.error(typeof message === "string" ? message : message.payload); });
    }

    property ServiceStatus _status: ServiceStatus {
        serviceName: Services.systemService.replace("luna://", "")
        clientName: prefs.clientName
        onAvailableChanged: {
            if (!available) {
                prefs._lost = true;
            } else if (prefs._lost || !prefs._loaded) {
                // Back, or there before the first answer, which then may
                // never come: a call made while it was away was refused.
                prefs._lost = false;
                prefs._subscribe();
            }
        }
    }

    property LunaService _service: LunaService {
        id: service
        onInitialized: {
            prefs._ready = true;
            prefs._subscribe();
        }
    }
}
