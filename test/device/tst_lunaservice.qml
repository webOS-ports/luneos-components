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
 * (exeName /usr/bin/qmltestrunner, allowedNames ["qmltestrunner",
 * "org.webosports.lstest"]) and "networkconnection.query" for
 * connectionmanager/getStatus, which answers a subscription at once and keeps
 * it open. The registerMethod tests register org.webosports.lstest, which
 * also needs a static services.d entry, and their methods
 * (org.webosports.lstest/lstest/*) a group, at trust level "dev", that the
 * caller has.
 *
 * Ending a call from its own callback deleted the call while LunaService was
 * still in it, and it went on with the freed object: Settings' System Updates
 * page crashed (SIGSEGV in LSCallCancel) when its download finished. A plain
 * run need not crash on that, so run it with AddressSanitizer too, which
 * reports the heap-use-after-free if it is back.
 *
 * A method registered by a LunaService that is gone was routed to the freed
 * object, and two LunaServices of one name sent each other's calls to the
 * one that registered last; the registerMethod tests cover both.
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

    // The service the method tests register on (a name of its own, as the
    // hub wants a dot in one), and others of that name, which share its
    // handle.
    LunaService { id: host; name: "org.webosports.lstest" }

    Component {
        id: hostComponent
        LunaService { name: "org.webosports.lstest" }
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

    // The methods below are registered on host's handle and called through
    // the hub. The role also needs allowedNames "org.webosports.lstest", and
    // its methods ("org.webosports.lstest/lstest/*") a group the caller has.
    readonly property string ownUri: "luna://org.webosports.lstest/lstest/"

    function callOwn(method, onReply) {
        bus.call(ownUri + method, "{}", function(message) {
            onReply(JSON.parse(message.payload));
        }, function(error) {
            fail(method + " failed: " + error);
        });
    }

    function test_registeredMethodAnswers() {
        verify(host.registerMethod("/lstest", "echo", function(message) {
            return JSON.stringify({ returnValue: true, from: "bus" });
        }));
        // A second registration from the same LunaService is refused.
        verify(!host.registerMethod("/lstest", "echo", function(message) {
            return JSON.stringify({ returnValue: true, from: "again" });
        }));
        var reply = null;
        callOwn("echo", function(r) { reply = r; });
        tryVerify(function() { return reply !== null; }, 10000);
        compare(reply.from, "bus");
    }

    function test_twoServicesOfOneNameKeepTheirMethods() {
        // Both have host's name and so share its handle: each
        // method still reaches the LunaService that registered it.
        var other = createTemporaryObject(hostComponent, test);
        verify(other !== null);
        verify(host.registerMethod("/lstest", "first", function(message) {
            return JSON.stringify({ returnValue: true, from: "bus" });
        }));
        verify(other.registerMethod("/lstest", "second", function(message) {
            return JSON.stringify({ returnValue: true, from: "other" });
        }));
        var first = null, second = null;
        callOwn("first", function(r) { first = r; });
        callOwn("second", function(r) { second = r; });
        tryVerify(function() { return first !== null && second !== null; }, 10000);
        compare(first.from, "bus");
        compare(second.from, "other");
    }

    function test_methodOfDestroyedServiceGetsAnError() {
        var gone = createTemporaryObject(hostComponent, test);
        verify(gone !== null);
        verify(gone.registerMethod("/lstest", "orphan", function(message) {
            return JSON.stringify({ returnValue: true, from: "gone" });
        }));
        gone.destroy();
        wait(0);
        // The handle lives on (host holds it) and so does the method; the call
        // reaches no freed LunaService, and is answered.
        var reply = null;
        callOwn("orphan", function(r) { reply = r; });
        tryVerify(function() { return reply !== null; }, 10000);
        compare(reply.returnValue, false);

        // Another LunaService of the name may take the method over.
        var next = createTemporaryObject(hostComponent, test);
        verify(next.registerMethod("/lstest", "orphan", function(message) {
            return JSON.stringify({ returnValue: true, from: "next" });
        }));
        reply = null;
        callOwn("orphan", function(r) { reply = r; });
        tryVerify(function() { return reply !== null; }, 10000);
        compare(reply.from, "next");
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
