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

    SystemPreferences { id: unread }

    AppLauncher { id: launcher }

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

    function test_one_name_per_service() {
        compare(Services.bus, "luna://com.webos.service.bus");
        compare(Services.systemService, "luna://com.webos.service.systemservice");
        compare(Services.applicationManager, "luna://com.webos.service.applicationmanager");
        compare(Services.resourceHandler, "luna://com.palm.applicationManager");
    }
}
