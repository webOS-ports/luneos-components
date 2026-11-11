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
import LuneOS.System 1.0

/*
 * LuneOS.System's helpers against the LunaService stub:
 *   qmltestrunner -import modules -import test/imports -input test/tst_service_helpers.qml
 */
TestCase {
    name: "ServiceHelpers"

    ServiceStatus { id: status; serviceName: "com.webos.service.systemservice" }

    SystemPreferences { id: prefs; keys: ["timeFormat"] }
    SignalSpy { id: changedSpy; target: prefs; signalName: "changed" }
    SignalSpy { id: updatedSpy; target: prefs; signalName: "updated" }

    SystemPreferences { id: unread }

    AppLauncher { id: launcher }

    SystemPreferences {
        id: lockWriter
        // What the store first says, before any test writes it
        property var firstRotationLock
        keys: ["rotationLock"]
        onUpdated: (response) => {
            if (firstRotationLock === undefined)
                firstRotationLock = response.rotationLock;
        }
    }
    Component {
        id: watcherComponent
        SystemPreferences {
            property int heard: 0
            keys: ["rotationLock"]
            onChanged: heard++
        }
    }

    function test_status_follows_the_bus() {
        tryCompare(status, "known", true);
        compare(status.available, true);
    }

    function test_status_resets_for_a_new_service() {
        tryCompare(status, "known", true);
        status.serviceName = "";
        compare(status.known, false);
        compare(status.available, false);
        status.serviceName = "com.webos.service.systemservice";
        tryCompare(status, "available", true);
    }

    function test_preferences_load_and_report() {
        tryCompare(prefs, "loaded", true);
        verify(prefs.values.hasOwnProperty("timeFormat"));
        compare(prefs.value("timeFormat", "x"), prefs.values.timeFormat);
        compare(prefs.value("notAKey", "fallback"), "fallback");
        verify(changedSpy.count >= 1);
        compare(changedSpy.signalArguments[0][0], "timeFormat");
        verify(updatedSpy.count >= 1);
        compare(updatedSpy.signalArguments[0][0].timeFormat, prefs.values.timeFormat);
    }

    function test_no_write_before_the_first_read() {
        // No keys, so nothing is ever read: every write must be refused.
        compare(unread.loaded, false);
        compare(unread.set("timeFormat", "HH24"), false);
        compare(unread.setMany({ "timeFormat": "HH24" }), false);
    }

    function test_write_after_the_first_read() {
        tryCompare(prefs, "loaded", true);
        compare(prefs.set("timeFormat", "HH24"), true);
    }

    function test_launch_reports_success_and_failure() {
        var done = null, failed = null;
        launcher.launch("org.webosports.app.settings.wifi", { "page": "x" },
                        function (r) { done = r; }, function (e) { failed = e; });
        tryVerify(function () { return done !== null; });
        compare(failed, null);

        done = null;
        launcher.launch("", null, function (r) { done = r; }, function (e) { failed = e; });
        tryVerify(function () { return failed !== null; });
        compare(done, null);
    }

    function test_open_goes_to_the_resource_handler() {
        var done = null, failed = null;
        launcher.open("https://www.webosports.org", function (r) { done = r; },
                      function (e) { failed = e; });
        tryVerify(function () { return done !== null; });

        launcher.open("", function (r) { done = "wrong"; }, function (e) { failed = e; });
        tryVerify(function () { return failed !== null; });
    }

    function test_open_takes_an_empty_reason_as_done() {
        // What the older manager answers after it has opened the target.
        var done = null, failed = null;
        launcher._send("luna://com.palm.applicationManager", "/openQuirk", {},
                       function (r) { done = r; }, function (e) { failed = e; }, true);
        tryVerify(function () { return done !== null; });
        compare(failed, null);
    }

    function test_rotation_lock_reads_as_an_angle() {
        // 400 is free; anything else is the locked angle. A false here
        // read as locked at 0 to everything that takes it as a number.
        tryCompare(lockWriter, "loaded", true);
        compare(lockWriter.firstRotationLock, 400);
    }

    function test_a_destroyed_page_hears_no_more() {
        tryCompare(lockWriter, "loaded", true);
        var gone = watcherComponent.createObject(null);
        var stays = createTemporaryObject(watcherComponent, null);
        tryCompare(gone, "loaded", true);
        tryCompare(stays, "loaded", true);
        var before = stays.heard;
        gone.destroy();
        wait(0);

        // Before the stub ended its subscriptions, this reached the
        // destroyed one too and threw on its properties.
        verify(lockWriter.set("rotationLock", 90));
        tryVerify(function () { return stays.heard > before; });
        verify(lockWriter.set("rotationLock", 400));
        tryCompare(stays.values, "rotationLock", 400);
    }

    function test_new_keys_end_the_old_subscription() {
        tryCompare(lockWriter, "loaded", true);
        var w = createTemporaryObject(watcherComponent, null);
        tryCompare(w, "loaded", true);
        w.keys = ["timeFormat"];
        tryCompare(w, "loaded", true);
        var before = w.heard;
        verify(lockWriter.set("rotationLock", 180));
        verify(lockWriter.set("rotationLock", 400));
        wait(50);
        compare(w.heard, before, "rotationLock is no longer asked for");
    }

    function test_one_name_per_service() {
        compare(Services.bus, "luna://com.webos.service.bus");
        compare(Services.systemService, "luna://com.webos.service.systemservice");
        compare(Services.applicationManager, "luna://com.webos.service.applicationmanager");
        compare(Services.resourceHandler, "luna://com.palm.applicationManager");
    }
}
