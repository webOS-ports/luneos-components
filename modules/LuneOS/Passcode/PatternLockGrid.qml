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

import QtQuick 2.9
// Units & font sizes
import LunaNext.Common 0.1

/*
 * The Android-style 3x3 pattern grid, for the Pattern lock mode.
 *
 * A single MouseArea covers the whole grid rather than one per dot: the
 * finger only has to pass near a node to select it, the way the real thing
 * behaves, which a per-dot MouseArea (each barely bigger than the dot itself)
 * would not give you.
 *
 * "patternDrawn" only fires for a pattern of at least minimumLength dots -
 * Android's own rule, so a stray tap cannot become a one-dot "pattern" nobody
 * could ever redraw reliably. Anything shorter reports "tooShort" instead.
 *
 * The pattern is encoded as the visited dots' indices joined by "-"
 * ("0-1-2-5-8"), row by row from the top left. Settings stores what it gets
 * here as the device passcode and the lock screen hands what it gets here to
 * matchDevicePasscode, so the two must be the same component: a pattern set
 * in one and drawn in the other has to come out as the same string.
 *
 * "started" fires as each attempt begins, so a caller can clear a "try
 * again" message; "drawing" is true while the finger is down (the lock
 * screen keeps the display awake meanwhile, as one long drag never counts as
 * activity).
 */
Item {
    id: patternGrid

    property int minimumLength: 4
    // Node colours. The defaults suit a light page; the lock screen passes
    // its own, closer to the dark PadLock chrome.
    property color dotColor: "#9a9a9a"
    property color selectedColor: "#2a7fd4"
    property color errorColor: "#be0003"
    // How solid an unvisited dot is drawn (the lock screen's white dots are
    // dimmed), and its radius as a share of a cell.
    property real dotOpacity: 1.0
    property real nodeSize: 0.12

    readonly property bool drawing: _dragging

    signal started()
    signal patternDrawn(string encoded)
    signal tooShort()

    implicitWidth: Units.gu(36)
    implicitHeight: Units.gu(36)

    readonly property int _columns: 3
    readonly property real _cellSize: Math.min(width, height) / _columns
    readonly property real _nodeRadius: _cellSize * nodeSize
    readonly property real _hitRadius: _cellSize * 0.38

    // Indices of the nodes visited so far, in order
    property var _selected: []
    property bool _dragging: false
    property bool _showError: false
    property point _dragPoint: Qt.point(0, 0)

    // Everything the canvas draws with: a change to any of it repaints
    readonly property var _paintState: [_selected, _dragging, _showError, _dragPoint,
                                        dotColor, selectedColor, errorColor, dotOpacity,
                                        _cellSize, _nodeRadius]
    on_PaintStateChanged: canvas.requestPaint()

    function _nodeCenter(index) {
        var col = index % _columns;
        var row = Math.floor(index / _columns);
        return Qt.point((col + 0.5) * _cellSize + (width - _cellSize * _columns) / 2,
                        (row + 0.5) * _cellSize + (height - _cellSize * _columns) / 2);
    }

    function _nodeAt(point) {
        for (var i = 0; i < _columns * _columns; i++) {
            var center = _nodeCenter(i);
            var dx = point.x - center.x;
            var dy = point.y - center.y;
            if (Math.sqrt(dx * dx + dy * dy) <= _hitRadius)
                return i;
        }
        return -1;
    }

    // Clears the drawn pattern, so the popup can reuse the same grid for a
    // second draw (the confirm step) or after a mismatch.
    function reset() {
        _selected = [];
        _dragging = false;
        _showError = false;
    }

    function showError() {
        _showError = true;
    }

    MouseArea {
        anchors.fill: parent

        onPressed: (mouse) => {
            patternGrid._showError = false;
            var node = patternGrid._nodeAt(Qt.point(mouse.x, mouse.y));
            patternGrid._selected = node >= 0 ? [node] : [];
            patternGrid._dragging = true;
            patternGrid._dragPoint = Qt.point(mouse.x, mouse.y);
            patternGrid.started();
        }

        onPositionChanged: (mouse) => {
            if (!patternGrid._dragging)
                return;

            patternGrid._dragPoint = Qt.point(mouse.x, mouse.y);

            var node = patternGrid._nodeAt(Qt.point(mouse.x, mouse.y));
            if (node >= 0 && patternGrid._selected.indexOf(node) < 0) {
                var updated = patternGrid._selected.slice();
                updated.push(node);
                patternGrid._selected = updated;
            }
        }

        onReleased: {
            patternGrid._dragging = false;

            if (patternGrid._selected.length >= patternGrid.minimumLength)
                patternGrid.patternDrawn(patternGrid._selected.join("-"));
            else if (patternGrid._selected.length > 0)
                patternGrid.tooShort();
        }
    }

    Canvas {
        id: canvas
        objectName: "canvas"
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var lineColor = patternGrid._showError ? patternGrid.errorColor
                                                    : patternGrid.selectedColor;

            // The connecting lines, under the dots.
            if (patternGrid._selected.length > 0) {
                ctx.strokeStyle = lineColor;
                ctx.lineWidth = Units.gu(0.5);
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.beginPath();

                var start = patternGrid._nodeCenter(patternGrid._selected[0]);
                ctx.moveTo(start.x, start.y);
                for (var i = 1; i < patternGrid._selected.length; i++) {
                    var point = patternGrid._nodeCenter(patternGrid._selected[i]);
                    ctx.lineTo(point.x, point.y);
                }
                // Follow the finger to the last node it is passing over.
                if (patternGrid._dragging)
                    ctx.lineTo(patternGrid._dragPoint.x, patternGrid._dragPoint.y);
                ctx.stroke();
            }

            // The nine dots.
            for (var n = 0; n < 9; n++) {
                var center = patternGrid._nodeCenter(n);
                var visited = patternGrid._selected.indexOf(n) >= 0;

                ctx.beginPath();
                ctx.arc(center.x, center.y, patternGrid._nodeRadius, 0, Math.PI * 2);
                ctx.fillStyle = visited ? lineColor : patternGrid.dotColor;
                ctx.globalAlpha = visited ? 1.0 : patternGrid.dotOpacity;
                ctx.fill();
                ctx.globalAlpha = 1.0;

                if (visited) {
                    ctx.beginPath();
                    ctx.arc(center.x, center.y, patternGrid._nodeRadius * 2.2, 0, Math.PI * 2);
                    ctx.strokeStyle = lineColor;
                    ctx.lineWidth = Units.gu(0.15);
                    ctx.stroke();
                }
            }
        }
    }
}
