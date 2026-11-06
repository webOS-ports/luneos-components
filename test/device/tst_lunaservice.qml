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
import QtTest
import LuneOS.Service 1.0

/*
 * LunaService calls against a device's bus:
 *
 *   qmltestrunner -import <dir with the LuneOS/Service to test> \
 *       -input tst_lunaservice.qml
 *
 * The calls go out under qmltestrunner's name; the hub needs a role for it
 * (exeName /usr/bin/qmltestrunner, allowedNames ["qmltestrunner"]) and
 * "networkconnection.query" for connectionmanager/getStatus, which answers a
 * subscription at once and keeps it open.
 *
 * Ending a call from its own callback deleted the call while LunaService was
 * still in it, and it went on with the freed object: Settings' System Updates
 * page crashed (SIGSEGV in LSCallCancel) when its download finished. A plain
 * run need not crash on that, so run it with AddressSanitizer too, which
 * reports the heap-use-after-free if it is back.
 */
TestCase {
    id: test
    name: "LunaServiceDevice"

    readonly property string statusUri: "luna://com.webos.service.connectionmanager/getStatus"

    LunaService { id: bus }

    Component {
        id: serviceComponent
        LunaService { }
    }

    function test_cancelInItsOwnCallback() {
        var replies = 0;
        var call = null;
        call = bus.subscribe(statusUri, JSON.stringify({ subscribe: true }), function(message) {
            replies++;
            call.cancel();
        }, function(error) {
            fail("getStatus failed: " + error);
        });
        verify(call !== null);
        tryVerify(function() { return replies > 0; }, 10000);
        // The call is gone; a second subscription on the same LunaService
        // still works, so its list of calls survived.
        var again = 0;
        var second = bus.subscribe(statusUri, JSON.stringify({ subscribe: true }), function(message) {
            again++;
        }, function(error) {
            fail("getStatus failed: " + error);
        });
        tryVerify(function() { return again > 0; }, 10000);
        second.cancel();
        compare(replies, 1);
    }

    function test_oneReplyCancelledInItsCallback() {
        var replies = 0;
        var call = null;
        call = bus.call(statusUri, "{}", function(message) {
            replies++;
            // A one-reply call ends itself after this; cancelling it first
            // must not end it twice.
            call.cancel();
        }, function(error) {
            fail("getStatus failed: " + error);
        });
        tryVerify(function() { return replies > 0; }, 10000);
        wait(200);
        compare(replies, 1);
    }

    function test_serviceDestroyedInItsCallback() {
        var service = createTemporaryObject(serviceComponent, test);
        verify(service !== null);
        var replies = 0;
        service.subscribe(statusUri, JSON.stringify({ subscribe: true }), function(message) {
            replies++;
            // destroy() deletes it once the callback has returned; its
            // open subscription is cancelled with it.
            service.destroy();
        }, function(error) {
            fail("getStatus failed: " + error);
        });
        tryVerify(function() { return replies > 0; }, 10000);
        wait(200);
        compare(replies, 1);
    }
}
