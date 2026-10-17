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
import LuneOS.Components 1.0 as LC

/*
 * The selection handles of a TextField or TextArea: one at each end of the
 * selection while the field has focus and something in it is selected, each
 * dragged to move its end. control is the TextInput or TextEdit (the
 * control itself); the handles are laid out in its coordinates.
 *
 * Holding a finger on the text selects the word under it, as legacy webOS
 * did, and so brings the handles up. Only the template's pressAndHold does
 * it: a tap still places the cursor, a drag still selects as it did, and a
 * TextArea scrolled by a flick is never held.
 */
Item {
    id: handles

    property Item control

    readonly property bool shown: !!control && control.activeFocus && control.selectedText.length > 0
    // A TextInput's positionToRectangle() leaves out its padding, which
    // positionAt() and the drawn text count; a TextEdit's counts it (it has
    // a lineCount, a TextInput has none).
    readonly property point offset: !control || control.lineCount !== undefined ? Qt.point(0, 0)
                                    : Qt.point(control.leftPadding, control.topPadding)
    readonly property rect startRect: shown ? at(control.selectionStart) : Qt.rect(0, 0, 0, 0)
    readonly property rect endRect: shown ? at(control.selectionEnd) : Qt.rect(0, 0, 0, 0)

    function at(position) {
        var r = control.positionToRectangle(position);
        return Qt.rect(r.x + offset.x, r.y + offset.y, r.width, r.height);
    }

    visible: shown
    z: 1

    // The word under (x, y), in the control's coordinates: letters and digits
    // up to a space or a punctuation mark either side. On a space, or past
    // the end of the text, the cursor goes there and nothing is selected.
    function selectWordAt(x, y) {
        if (!control.activeFocus)
            control.forceActiveFocus();
        var pos = control.positionAt(x, y);
        // positionAt() gives the nearest gap between characters; the one
        // under the finger is on the side of it that x is on
        var under = x < at(pos).x ? pos - 1 : pos;
        var text = control.getText(0, control.length);
        var isWord = function(i) { return i >= 0 && i < text.length && !/[\s.,;:!?"'()\[\]{}<>\/\\|]/.test(text.charAt(i)); };
        control.cursorPosition = pos;
        if (!isWord(under))
            return;
        var start = under, end = under + 1;
        while (isWord(start - 1))
            --start;
        while (isWord(end))
            ++end;
        control.select(start, end);
    }

    // Where the control was in the window when the finger went down. Inside
    // a ScrollView the moves go to the Flickable, and Qt's hold timer, which
    // never sees them, can still fire while the text is being scrolled; a
    // hold after the text has moved under the finger is a flick, not a hold.
    property point pressedAt

    Connections {
        target: handles.control
        function onPressed(event) {
            handles.pressedAt = handles.control.mapToItem(null, 0, 0);
        }
        function onPressAndHold(event) {
            var now = handles.control.mapToItem(null, 0, 0);
            var slack = Qt.styleHints.startDragDistance;
            if (Math.abs(now.x - handles.pressedAt.x) > slack || Math.abs(now.y - handles.pressedAt.y) > slack)
                return;
            handles.selectWordAt(event.x, event.y);
        }
    }

    LC.SelectionHandle {
        objectName: "selectionStartHandle"
        start: true
        tipX: handles.startRect.x
        tipY: handles.startRect.y
        onDragged: function(x, y) {
            var pos = handles.control.positionAt(x, y + handles.startRect.height / 2);
            handles.control.select(Math.min(pos, handles.control.selectionEnd - 1), handles.control.selectionEnd);
        }
    }

    LC.SelectionHandle {
        objectName: "selectionEndHandle"
        tipX: handles.endRect.x
        tipY: handles.endRect.y + handles.endRect.height
        onDragged: function(x, y) {
            var pos = handles.control.positionAt(x, y - handles.endRect.height / 2);
            handles.control.select(handles.control.selectionStart, Math.max(pos, handles.control.selectionStart + 1));
        }
    }
}
