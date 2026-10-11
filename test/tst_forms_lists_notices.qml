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
import LuneOS.Forms 1.0

/*
 * ListPicker's searching and ServiceUnavailableNotice's following of a
 * service:
 *   qmltestrunner -import modules -import test/imports -input test/tst_forms_lists_notices.qml
 */
Item {
    width: 400
    height: 600

    function makeEntries(n) {
        var list = [];
        for (var i = 0; i < n; i++)
            list.push({ "key": "k" + i, "label": "Entry " + i, "sublabel": i === 3 ? "special" : "" });
        return list;
    }

    ListPicker {
        id: picker
        anchors.fill: parent
        entries: makeEntries(5)
    }
    SignalSpy { id: picked; target: picker; signalName: "picked" }

    // A stand-in for LuneOS.System's ServiceStatus
    QtObject {
        id: status
        property string serviceName: "org.example.service"
        property bool known: false
        property bool available: false
    }
    ServiceUnavailableNotice { id: notice; status: status; description: "x" }

    TestCase {
        name: "ListsAndNotices"
        when: windowShown

        function test_short_lists_are_not_searchable() {
            picker.entries = makeEntries(5);
            verify(!picker.searchable);
            picker.entries = makeEntries(12);
            verify(picker.searchable);
        }

        function test_search_matches_label_and_sublabel() {
            picker.entries = makeEntries(20);
            picker.clearSearch();
            compare(picker.visibleEntries.length, 20);
            // Type through the field the way a user would
            var input = null;
            for (var i = 0; i < picker.children[0].children.length; i++)
                if (picker.children[0].children[i].placeholderText === "Search")
                    input = picker.children[0].children[i];
            verify(input !== null);
            input.text = "entry 1";
            compare(picker.visibleEntries.length, 11);   // 1 and 10..19
            input.text = "special";
            compare(picker.visibleEntries.length, 1);
            compare(picker.visibleEntries[0].key, "k3");
            input.text = "nothing like it";
            compare(picker.visibleEntries.length, 0);
            picker.clearSearch();
        }

        function test_title_and_subtitle_entries() {
            picker.entries = [{ "title": "TVs", "subtitle": "12", "id": "tv" }];
            compare(picker._label(picker.entries[0]), "TVs");
            compare(picker._note(picker.entries[0]), "12");
        }

        function test_notice_follows_the_service() {
            compare(notice.serviceName, "org.example.service");
            status.known = false;
            verify(!notice.visible);           // not asked yet: no flash of a notice
            status.known = true;
            status.available = false;
            verify(notice.visible);
            status.available = true;
            verify(!notice.visible);
        }

        function test_colours_are_the_ones_the_apps_used() {
            compare(String(Colors.secondaryText), "#666666");
            compare(String(Colors.error), "#be0003");
            compare(String(Colors.pageBackground), "#d8d8d8");
            compare(String(Colors.noticeBackground), "#f4ecd0");
        }
    }
}
