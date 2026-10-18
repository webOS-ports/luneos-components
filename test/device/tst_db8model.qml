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
 * Db8Model against a device's db8 (not the desktop stand-in), with a kind of
 * its own that it removes again:
 *
 *   qmltestrunner -import <dir with the LuneOS/Service to test> \
 *       -input tst_db8model.qml
 *
 * The calls go out under qmltestrunner's name, which db8 makes the kind's
 * owner; the hub needs a role for it (exeName /usr/bin/qmltestrunner,
 * allowedNames ["qmltestrunner"]) and "database.operation".
 */
TestCase {
    id: test
    name: "Db8ModelDevice"

    readonly property string testKind: "org.webosports.test.db8model:1"

    Db8Model { id: writer }
    Db8Model { id: onePage; query: ({ limit: 500 }) }
    Db8Model { id: everything; query: ({ limit: 500 }); allPages: true }
    Db8Model { id: watched; query: ({ limit: 500 }); allPages: true; watch: true }
    Db8Model { id: broken; kind: "org.webosports.test.nosuchkind:1" }
    Db8Model { id: leftovers; query: ({ limit: 500, select: ["_id"] }); allPages: true }
    LunaService { id: bus }

    SignalSpy { id: brokenErrors; target: broken; signalName: "error" }

    function callAndWait(fn) {
        var reply = null;
        fn(function(r) { reply = r; });
        tryVerify(function() { return reply !== null; }, 10000);
        return reply;
    }

    function initTestCase() {
        var r = callAndWait(function(done) {
            writer.putKind({ id: testKind, owner: Qt.application.name,
                             indexes: [{ name: "n", props: [{ name: "n" }] }] }, done);
        });
        verify(r.returnValue, JSON.stringify(r));
        writer.kind = testKind;
        // A clean start: rows of an earlier run go.
        removeAll();
        var rows = [];
        for (var i = 0; i < 1200; i++)
            rows.push({ n: i });
        for (var b = 0; b < 1200; b += 400) {
            var put = callAndWait(function(done) { writer.put(rows.slice(b, b + 400), done); });
            verify(put.returnValue, JSON.stringify(put));
            compare(put.results.length, 400);
        }
    }

    function removeAll() {
        leftovers.kind = testKind;
        leftovers.refresh();
        tryCompare(leftovers, "status", "ready", 20000);
        var ids = [];
        for (var i = 0; i < leftovers.count; i++)
            ids.push(leftovers.get(i)._id);
        for (var b = 0; b < ids.length; b += 400) {
            var r = callAndWait(function(done) { writer.del(ids.slice(b, b + 400), done); });
            verify(r.returnValue, JSON.stringify(r));
        }
    }

    function cleanupTestCase() {
        var done = false;
        bus.call("luna://com.palm.db/delKind", JSON.stringify({ id: testKind }),
                 function() { done = true; }, function() { done = true; });
        tryVerify(function() { return done; }, 10000);
    }

    function test_1_unknown_kind_is_an_error_with_db8s_code() {
        tryCompare(broken, "status", "error", 10000);
        compare(broken.errorCode, -3970);
        verify(broken.errorText.length > 0);
        compare(brokenErrors.count, 1);
        compare(brokenErrors.signalArguments[0][1], -3970);
    }

    function test_2_one_page_or_all() {
        onePage.kind = testKind;
        everything.kind = testKind;
        tryCompare(onePage, "status", "ready", 10000);
        compare(onePage.count, 500);
        tryCompare(everything, "status", "ready", 20000);
        compare(everything.count, 1200);
        var seen = {};
        for (var i = 0; i < everything.count; i++)
            seen[everything.get(i).n] = true;
        compare(Object.keys(seen).length, 1200);
    }

    function test_3_watch_finds_again() {
        watched.kind = testKind;
        tryCompare(watched, "status", "ready", 20000);
        var before = watched.count;
        var put = callAndWait(function(done) { writer.put([{ n: 5000 }], done); });
        verify(put.returnValue);
        tryCompare(watched, "count", before + 1, 20000);
        tryCompare(watched, "status", "ready", 20000);

        var id = put.results[0].id;
        var merged = callAndWait(function(done) { writer.merge([{ _id: id, n: 5001 }], done); });
        verify(merged.returnValue, JSON.stringify(merged));
        var removed = callAndWait(function(done) { writer.del([id], done); });
        verify(removed.returnValue, JSON.stringify(removed));
        tryCompare(watched, "count", before, 20000);
    }

    function test_4_refresh_and_destroy_while_loading() {
        // A find in flight when the model goes: no reply may reach it.
        var c = Qt.createQmlObject('import LuneOS.Service 1.0; Db8Model { query: ({ limit: 100 }); allPages: true; watch: true }', test);
        c.kind = testKind;
        c.destroy();
        wait(500);
        everything.refresh();
        compare(everything.status, "loading");
        tryCompare(everything, "status", "ready", 20000);
        compare(everything.count, 1200);
    }
}
