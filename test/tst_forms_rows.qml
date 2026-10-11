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
 * FormGroup's rules between rows, and the value-based LabelAndSelector and
 * finer-stepped LabelAndSlider Phone's and Camera's preferences need:
 *   qmltestrunner -import modules -import test/imports -input test/tst_forms_rows.qml
 */
Item {
    width: 400
    height: 800

    FormGroup {
        id: group
        title: "Group"
        LabelAndValue { id: r1; label: "one" }
        LabelAndValue { id: r2; label: "two"; visible: false }
        LabelAndValue { id: r3; label: "three" }
        LabelAndValue { id: r4; label: "four" }
    }

    LabelAndSelector {
        id: selector
        y: 400; width: 400
        model: ["Off", "3 s", "10 s"]
        values: [0, 3, 10]
        value: 3
    }
    SignalSpy { id: chosen; target: selector; signalName: "chosen" }

    LabelAndSlider { id: whole; y: 500; width: 400 }
    SignalSpy { id: wholeMoved; target: whole; signalName: "moved" }
    LabelAndSlider { id: fine; y: 600; width: 400; from: -2; to: 2; stepSize: 0.5; value: 0
                     format: function(v) { return v.toFixed(1) + " EV"; } }
    SignalSpy { id: fineMoved; target: fine; signalName: "moved" }

    LabelAndTextField { id: textRow; y: 700; width: 400; label: "Forward to"; text: "123" }
    SignalSpy { id: committed; target: textRow; signalName: "committed" }
    SignalSpy { id: edited; target: textRow; signalName: "edited" }

    TestCase {
        name: "FormsRows"
        when: windowShown

        function separators() {
            return findChildren(group, function(o) { return o.hasOwnProperty("lastShown"); });
        }
        function findChildren(item, pred, acc) {
            acc = acc || [];
            if (pred(item)) acc.push(item);
            for (var i = 0; i < item.children.length; i++) findChildren(item.children[i], pred, acc);
            return acc;
        }

        function test_rows_stack_and_rules_sit_under_them() {
            // Rows that set no width of their own still take the group's and
            // are laid out one under the next (a zero-width row was skipped)
            verify(r1.width > 0);
            compare(r3.y, r1.y + r1.height);
            compare(r4.y, r3.y + r3.height);
            var under = separators().filter(function(s) { return s.visible && s.row === r1; })[0];
            compare(under.y, r1.y + r1.height - 1);
        }

        function test_rules_only_between_visible_rows() {
            var shown = separators().filter(function(s) { return s.visible; });
            // one, three, four are visible: a rule after one and after three
            compare(shown.length, 2);
            r4.visible = false;
            shown = separators().filter(function(s) { return s.visible; });
            compare(shown.length, 1);
            r4.visible = true;
        }

        function test_selector_works_in_values() {
            compare(selector.currentIndex, 1);
            selector.value = 10;
            compare(selector.currentIndex, 2);
            var combo = findChildren(selector, function(o) { return o.hasOwnProperty("popup") && o.hasOwnProperty("currentIndex"); })[0];
            combo.activated(0);
            compare(chosen.count, 1);
            compare(chosen.signalArguments[0][0], 0);
        }

        function test_text_commits_once_and_only_after_a_change() {
            var field = findChildren(textRow, function(o) { return o.hasOwnProperty("echoMode"); })[0];
            committed.clear(); edited.clear();

            // Leaving a field untouched writes nothing back
            field.forceActiveFocus();
            field.editingFinished();
            compare(committed.count, 0);

            // A new value set from outside is not the user's either
            textRow.text = "456";
            field.editingFinished();
            compare(committed.count, 0);

            // Typing: one edited per keystroke, one committed at the end
            field.forceActiveFocus();
            field.selectAll();
            keyClick(Qt.Key_7); keyClick(Qt.Key_8);
            compare(edited.count, 2);
            compare(committed.count, 0);
            keyClick(Qt.Key_Return);
            compare(committed.count, 1);
            compare(committed.signalArguments[0][0], "78");

            // And not again for the same edit
            field.editingFinished();
            compare(committed.count, 1);
        }

        function test_slider_rounds_whole_steps_only() {
            verify(whole.wholeNumbers);
            verify(!fine.wholeNumbers);
            var s1 = findChildren(whole, function(o) { return o.hasOwnProperty("snapMode"); })[0];
            s1.value = 41.6; s1.moved();
            compare(wholeMoved.signalArguments[0][0], 42);
            var s2 = findChildren(fine, function(o) { return o.hasOwnProperty("snapMode"); })[0];
            s2.value = 1.5; s2.moved();
            compare(fineMoved.signalArguments[0][0], 1.5);
            compare(fine.format(1.5), "1.5 EV");
        }
    }
}
