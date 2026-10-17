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
import QtQuick.Controls
import QtTest
import QtCore
import LuneOS.Forms 1.0
import LuneOS.Components 1.0

/*
 * IconToolButton, AppFiles, SelectionHandle, and the selection handles the
 * style's TextField and TextArea draw:
 *   XDG_CONFIG_HOME=<empty dir> QML_XHR_ALLOW_FILE_READ=1 \
 *   QT_QUICK_CONTROLS_STYLE=QtQuick.Controls.LuneOS \
 *   qmltestrunner -import modules -import test/imports -input test/tst_shared_app_parts.qml
 */
Item {
    id: root
    width: 480
    height: 800

    Row {
        IconToolButton { id: byImage; imageFolder: Qt.resolvedUrl("../modules/LuneOS/Components/images/"); image: "selection-handle" }
        IconToolButton { id: bySource; source: Qt.resolvedUrl("../modules/LuneOS/Components/images/selection-handle.svg"); appearance: "overlay"; checkable: true }
        IconToolButton { id: byLabel; label: "1.5×"; appearance: "plain" }
    }

    TextField {
        id: field
        y: 200
        x: 40
        width: 400
        text: "The quick brown fox jumps"
    }

    TextArea {
        id: area
        y: 400
        x: 40
        width: 400
        height: 200
        text: "One line\nand another line"
    }

    SelectionHandle {
        id: lone
        tipX: 100
        tipY: 700
    }

    SignalSpy { id: draggedSpy; target: lone; signalName: "dragged" }

    TestCase {
        name: "SharedAppParts"
        when: windowShown

        function find(item, name) {
            if (item.objectName === name)
                return item;
            for (var i = 0; i < item.children.length; ++i) {
                var f = find(item.children[i], name);
                if (f)
                    return f;
            }
            return null;
        }

        function test_iconbutton_sources_and_size() {
            compare(byImage.source.toString(), Qt.resolvedUrl("../modules/LuneOS/Components/images/selection-handle.svg").toString());
            verify(byImage.width >= 54 && byImage.height >= 54, "at least the legacy touch target");
            var img = find(byImage, "iconButtonImage");
            verify(img.visible);
            compare(img.width, byImage.iconSize);
            verify(!find(byLabel, "iconButtonImage").visible, "a label instead of a picture");
        }

        function test_iconbutton_appearances() {
            compare(byImage.background.color, Qt.color("transparent"), "toolbar: nothing while idle");
            byImage.checkable = true;
            byImage.checked = true;
            compare(byImage.background.color, Qt.color("#1d1d1d"));
            compare(byImage.background.border.color, Qt.color("#0c0c0c"));
            byImage.checked = false;
            bySource.checked = true;
            compare(bySource.background.color, Qt.color("#33ffffff"), "overlay: a light veil");
            bySource.checked = false;
            verify(!byLabel.background.visible, "plain: nothing behind it until held");
            mousePress(byLabel);
            verify(byLabel.background.visible);
            mouseRelease(byLabel);
        }

        function test_preferences_file_named_by_app() {
            compare(AppFiles.preferencesFile("org.example.test"),
                    StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/org.example.test/preferences.ini");
            var prefs = Qt.createQmlObject('import QtCore; import LuneOS.Components 1.0; Settings { location: AppFiles.preferencesFile("org.example.test"); category: "group"; property int answer: 0 }', root);
            prefs.answer = 42;
            prefs.sync();
            prefs.destroy();
            wait(0);
            var x = new XMLHttpRequest();
            x.open("GET", StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)
                   + "/org.example.test/preferences.ini", false);
            x.send();
            verify(x.responseText.indexOf("[group]") >= 0, x.responseText);
            verify(x.responseText.indexOf("answer=42") >= 0, x.responseText);
            verify(x.responseText.indexOf("appId") < 0, "only the app's own settings in its file");
        }

        function test_lone_handle_drag() {
            compare(lone.x, 100 - lone.width / 2);
            compare(lone.y, 700, "the end handle hangs below its point");
            lone.start = true;
            compare(lone.y, 700 - lone.height, "the start handle stands above it");
            lone.start = false;
            mousePress(lone, lone.width / 2, lone.height / 2);
            mouseMove(lone, lone.width / 2 + 30, lone.height / 2 + 5);
            mouseMove(lone, lone.width / 2 + 60, lone.height / 2 + 10);
            mouseRelease(lone, lone.width / 2 + 60, lone.height / 2 + 10);
            verify(draggedSpy.count > 0);
            var last = draggedSpy.signalArguments[draggedSpy.count - 1];
            fuzzyCompare(last[0], 160, 1);
            fuzzyCompare(last[1], 710, 1);
        }

        function test_field_handles_follow_and_move_the_selection() {
            var start = find(field, "selectionStartHandle");
            var end = find(field, "selectionEndHandle");
            verify(start && end);
            verify(!start.parent.visible, "no selection, no handles");
            field.forceActiveFocus();
            field.select(4, 9);
            verify(start.parent.visible);
            // Each end where the text is drawn: the field's padding counted
            // (positionAt() lands on the same position again)
            var r4 = field.positionToRectangle(4);
            r4.x += field.leftPadding;
            r4.y += field.topPadding;
            var r9 = field.positionToRectangle(9);
            r9.x += field.leftPadding;
            r9.y += field.topPadding;
            compare(field.positionAt(r9.x + 0.5, r9.y + r9.height / 2), 9);
            compare(start.tipX, r4.x);
            compare(start.tipY, r4.y);
            compare(end.tipX, r9.x);
            compare(end.tipY, r9.y + r9.height);
            // Drag the end handle to the end of "brown"
            var to = field.positionToRectangle(15);
            end.dragged(to.x + field.leftPadding + 0.5, to.y + field.topPadding + to.height);
            compare(field.selectionStart, 4);
            compare(field.selectionEnd, 15);
            compare(field.selectedText, "quick brown");
            // The start can be dragged up to, not past, the end
            start.dragged(r9.x + 200, r4.y);
            compare(field.selectionStart, 14);
            compare(field.selectionEnd, 15);
            field.deselect();
            verify(!start.parent.visible);
        }

        function test_area_handles_on_two_lines() {
            var end = find(area, "selectionEndHandle");
            area.forceActiveFocus();
            // A TextEdit's rectangles already count its padding
            var r4 = area.positionToRectangle(4);
            var r = area.positionToRectangle(12);
            compare(area.positionAt(r.x + 0.5, r.y + r.height / 2), 12);
            area.select(4, 12);
            verify(end.parent.visible);
            compare(end.tipX, r.x);
            compare(end.tipY, r.y + r.height);
            verify(r.y > r4.y, "the end is on the second line");
            // Dragged to the start of the second line's last word
            var to = area.positionToRectangle(21);
            end.dragged(to.x + 0.5, to.y + to.height);
            compare(area.selectionEnd, 21);
            field.forceActiveFocus();
            verify(!end.parent.visible, "only while the field has focus");
        }
    }
}
