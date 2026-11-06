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

import QtQuick
import LuneOS.Service 1.0

/*
 * An app run by qml-runner must not get a LunaService under another app's
 * ID. Run it as org.webosports.lstest.app, with the LuneOS/Service to test
 * copied next to this file (qml-runner imports from the app's folder first):
 *
 *   qml-runner '{"main":"file://<this dir>/main.qml","appId":"org.webosports.lstest.app"}'
 *
 * qml-runner logs to the journal. Expected: "LunaService: an app
 * org.webosports.lstest.app may not use the name com.palm.app.preware2", and
 * the hub registers no com.palm.app.preware2-<pid>. Before the check the hub
 * registered it, and the call went out with Preware's permissions.
 */
Item {
    property int done: 0
    function report(what, text) { console.log("S1 " + what + ": " + text); if (++done == 2) Qt.quit(); }

    LunaService { id: foreign; name: "com.palm.app.preware2" }
    LunaService { id: own }

    Component.onCompleted: {
        foreign.call("luna://com.webos.service.connectionmanager/getStatus", "{}",
                     function(m) { report("foreign", "answered " + m.payload.substring(0, 40)); },
                     function(e) { report("foreign", "error " + e); });
        own.call("luna://com.webos.service.connectionmanager/getStatus", "{}",
                 function(m) { report("own", "answered " + m.payload.substring(0, 40)); },
                 function(e) { report("own", "error " + e); });
    }
}
