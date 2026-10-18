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
 * The desktop stand-in for Db8Model has the device one's API - status,
 * the calls with their callbacks, get() as plain objects, a kind set late
 * (test/device/tst_db8model.qml is the same against a device's db8):
 *   qmltestrunner -import modules -import test/imports -input test/tst_db8model.qml
 */
TestCase {
    name: "Db8ModelStandIn"

    readonly property string testKind: "org.webosports.test.standin:1"

    Db8Model { id: writer; kind: testKind }
    Db8Model { id: late; query: ({}); allPages: true }

    function test_1_calls_answer_their_callbacks() {
        var kindReply = null;
        writer.putKind({ id: testKind, owner: "test" }, function(r) { kindReply = r; });
        verify(kindReply.returnValue);

        var put = null;
        writer.put([{ name: "One", tags: ["a", "b"] }, { name: "Two", tags: [] }], function(r) { put = r; });
        verify(put.returnValue);
        compare(put.results.length, 2);
        verify(put.results[0].id !== undefined);

        var merged = null;
        writer.merge([{ _id: put.results[0].id, name: "Uno" }], function(r) { merged = r; });
        verify(merged.returnValue);
        compare(merged.count, 1);
    }

    function test_2_a_kind_set_late_is_read_and_rows_are_plain() {
        compare(late.status, "null");
        late.kind = testKind;
        compare(late.status, "ready");
        compare(late.count, 2);
        var one = null;
        for (var i = 0; i < late.count; i++)
            if (late.get(i).name === "Uno")
                one = late.get(i);
        verify(one !== null);
        verify(Array.isArray(one.tags));
        compare(one.tags.length, 2);
    }

    function test_3_changes_reach_the_reader_and_del_answers() {
        var put = null;
        writer.put([{ name: "Three", tags: [] }], function(r) { put = r; });
        compare(late.count, 3);
        var removed = null;
        writer.del([put.results[0].id], function(r) { removed = r; });
        verify(removed.returnValue);
        compare(removed.count, 1);
        compare(late.count, 2);
        late.refresh();
        compare(late.status, "ready");
    }

    function test_4_a_model_that_goes_stops_listening() {
        // Declared with its kind, as apps do.
        var gone = Qt.createQmlObject('import LuneOS.Service 1.0; Db8Model { kind: "' + testKind + '"; query: ({}) }', late);
        compare(gone.count, late.count);
        gone.destroy();
        wait(0);
        // Writing after it went: no call into the dead one, and the other
        // reader is still told.
        var before = late.count;
        var put = null;
        writer.put([{ name: "Four", tags: [] }], function(r) { put = r; });
        verify(put.returnValue);
        compare(late.count, before + 1);
        writer.del([put.results[0].id]);
        compare(late.count, before);
    }
}
