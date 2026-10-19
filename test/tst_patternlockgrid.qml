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
import LuneOS.Passcode 1.0

/*
 * The pattern grid Settings sets a pattern with and the lock screen checks
 * it with. What it emits is stored as the device passcode, so the encoding
 * is the contract:
 *   qmltestrunner -import modules -import test/imports -input test/tst_patternlockgrid.qml
 */
Item {
    width: 300
    height: 300

    PatternLockGrid {
        id: grid
        anchors.fill: parent
    }

    SignalSpy { id: drawn; target: grid; signalName: "patternDrawn" }
    SignalSpy { id: tooShortSpy; target: grid; signalName: "tooShort" }
    SignalSpy { id: started; target: grid; signalName: "started" }
    SignalSpy { id: painted; signalName: "painted" }

    TestCase {
        name: "PatternLockGrid"
        when: windowShown

        // Centre of dot n, row by row from the top left
        function dot(n) {
            var cell = grid.width / 3;
            return Qt.point((n % 3 + 0.5) * cell, (Math.floor(n / 3) + 0.5) * cell);
        }

        function draw(dots) {
            var p = dot(dots[0]);
            mousePress(grid, p.x, p.y);
            for (var i = 1; i < dots.length; i++) {
                // Pass through the straight line between dots in steps, the
                // way a finger does, so no dot in between is skipped
                var a = dot(dots[i - 1]), b = dot(dots[i]);
                for (var t = 1; t <= 8; t++)
                    mouseMove(grid, a.x + (b.x - a.x) * t / 8, a.y + (b.y - a.y) * t / 8);
            }
            var last = dot(dots[dots.length - 1]);
            mouseRelease(grid, last.x, last.y);
        }

        function init() {
            grid.reset();
            drawn.clear();
            tooShortSpy.clear();
            started.clear();
        }

        function test_encodes_the_visited_dots_in_order() {
            draw([0, 1, 2, 5, 8]);
            compare(drawn.count, 1);
            compare(drawn.signalArguments[0][0], "0-1-2-5-8");
        }

        function test_a_dot_is_visited_once() {
            draw([4, 1, 2, 5, 4, 3]);
            compare(drawn.signalArguments[0][0], "4-1-2-5-3");
        }

        function test_short_patterns_are_refused() {
            draw([0, 1, 2]);
            compare(drawn.count, 0);
            compare(tooShortSpy.count, 1);
        }

        function test_each_attempt_starts_and_ends() {
            var p = dot(0);
            mousePress(grid, p.x, p.y);
            compare(started.count, 1);
            compare(grid.drawing, true);
            mouseRelease(grid, p.x, p.y);
            compare(grid.drawing, false);
        }

        // Lets a paint already asked for land first
        function settle() {
            do {
                painted.clear();
                wait(100);
            } while (painted.count > 0);
        }

        // Whatever the canvas draws with, changed, is drawn again
        function test_a_change_is_painted() {
            painted.target = findChild(grid, "canvas");
            verify(painted.target);
            var changes = [
                function() { grid.dotColor = "red"; },
                function() { grid.selectedColor = "green"; },
                function() { grid.errorColor = "blue"; },
                function() { grid.dotOpacity = 0.5; },
                function() { grid.nodeSize = 0.2; },
                function() { grid.showError(); },
                function() { grid.reset(); },
            ];
            for (var i = 0; i < changes.length; i++) {
                settle();
                changes[i]();
                painted.wait(1000);
            }
            var p = dot(0);
            settle();
            mousePress(grid, p.x, p.y);
            painted.wait(1000);
            settle();
            mouseMove(grid, p.x + 30, p.y + 30);
            painted.wait(1000);
            settle();
            mouseRelease(grid, p.x + 30, p.y + 30);
            painted.wait(1000);
            // Only the drawn dots change
            settle();
            grid.reset();
            painted.wait(1000);
        }
    }
}
