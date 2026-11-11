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
 * Which way the phone is held: OrientationFilter.js's rule (moved here from
 * luna-next-cardshell with its tests) and DeviceOrientation, fed samples by
 * hand - a runner without QtSensors has no accelerometer, and one with it
 * reads nothing useful from a desktop.
 *   qmltestrunner -import modules -import test/imports -input test/tst_device_orientation.qml
 *
 * Samples are built from a turn in the screen plane (0 = upright, positive
 * = counter-clockwise, i.e. towards the left edge being up) and a lean back
 * from vertical (0 = upright, 90 = flat on its back).
 */
Item {
    id: root

    readonly property real g: 9.80665

    function sample(turn, lean) {
        var t = turn * Math.PI / 180, l = lean * Math.PI / 180;
        var inPlane = g * Math.cos(l);
        return { x: -inPlane * Math.sin(t), y: inPlane * Math.cos(t), z: g * Math.sin(l) };
    }

    TestCase {
        name: "OrientationFilter"

        function next(turn, lean, current) {
            var s = root.sample(turn, lean);
            return OrientationFilter.orientationFor(s.x, s.y, s.z, current);
        }

        function test_angles_match_orientation_helper() {
            // Left edge up is 90, right edge up 270, as the shell uses them.
            compare(OrientationFilter.inPlaneAngle(-g, 0, 0), 90);
            compare(OrientationFilter.inPlaneAngle(g, 0, 0), 270);
            compare(OrientationFilter.inPlaneAngle(0, -g, 0), 180);
            compare(OrientationFilter.inPlaneAngle(0, g, 0), 0);
        }

        function test_small_turns_keep_portrait_data() {
            return [ { tag: "upright", lean: 0 }, { tag: "reading", lean: 50 }, { tag: "low", lean: 65 } ];
        }
        function test_small_turns_keep_portrait(data) {
            // sensorfw flipped here: at a 50 degree lean a 30 degree turn is
            // already past its thresholds.
            for (var turn = -55; turn <= 55; turn += 5)
                compare(next(turn, data.lean, 0), 0, "turn " + turn);
        }

        function test_turns_past_sixty_degrees() {
            compare(next(65, 40, 0), 90);
            compare(next(-65, 40, 0), 270);
            compare(next(90, 40, 0), 90);
        }

        function test_hysteresis_on_the_way_back() {
            // In landscape (90) it takes a turn back to within 30 of upright.
            compare(next(40, 30, 90), 90);
            compare(next(31, 30, 90), 90);
            compare(next(25, 30, 90), 0);
        }

        function test_upside_down() {
            compare(next(180, 20, 0), 180);
            compare(next(125, 20, 180), 180);
        }

        function test_flat_keeps_current() {
            compare(OrientationFilter.orientationFor(0, 0, g, 90), 90);
            // Lying almost flat, a turn says nothing.
            compare(next(90, 80, 0), 0);
        }

        function test_shaking_keeps_current() {
            var s = root.sample(90, 0);
            compare(OrientationFilter.orientationFor(s.x * 2, s.y * 2, s.z * 2, 0), 0);
            compare(OrientationFilter.orientationFor(s.x * 0.3, s.y * 0.3, s.z * 0.3, 0), 0);
        }
    }

    Component { id: orientationComponent; DeviceOrientation { settleInterval: 50 } }
    SystemPreferences { id: writer; keys: ["rotationLock"] }

    TestCase {
        name: "DeviceOrientation"

        function make(props) {
            return createTemporaryObject(orientationComponent, root, props || {});
        }

        function feed(o, turn) {
            var s = root.sample(turn, 30);
            o.sample(s.x, s.y, s.z);
        }

        function test_starts_upright() {
            var o = make();
            compare(o.angle, 0);
            compare(o.turns, 0);
            compare(o.screenAngle, 0);
            compare(o.rotationLocked, false);
        }

        function test_a_turn_counts_once_it_has_held() {
            var o = make();
            feed(o, 90);
            compare(o.angle, 0, "not before it has held");
            tryCompare(o, "angle", 90);
            compare(o.turns, 1);
            compare(o.screenTurns, 1, "the screen turns with the phone while not locked");
            feed(o, -90);
            tryCompare(o, "turns", 3);
        }

        function test_passing_through_does_not_count() {
            var o = make({ settleInterval: 200 });
            var changes = 0;
            o.angleChanged.connect(function() { changes++; });
            feed(o, 90);
            wait(50);
            feed(o, 180);
            tryCompare(o, "angle", 180);
            compare(changes, 1, "straight to upside down, not by way of 90");
        }

        function test_turning_back_in_time_keeps_it() {
            var o = make({ settleInterval: 200 });
            feed(o, 90);
            wait(50);
            feed(o, 0);
            wait(300);
            compare(o.angle, 0);
        }

        function test_stopping_drops_what_was_pending() {
            var o = make({ settleInterval: 100 });
            feed(o, 90);
            o.active = false;
            wait(200);
            compare(o.angle, 0);
        }

        function test_the_screen_stays_at_a_locked_angle() {
            var o = make({ followRotationLock: true });
            tryCompare(writer, "loaded", true);
            verify(writer.set("rotationLock", 270));
            tryCompare(o, "rotationLocked", true);
            compare(o.screenAngle, 270);
            feed(o, 90);
            tryCompare(o, "angle", 90);
            compare(o.screenAngle, 270, "the phone turns, the screen does not");
            compare(o.screenTurns, 3);

            verify(writer.set("rotationLock", 400));
            tryCompare(o, "rotationLocked", false);
            compare(o.screenAngle, 90);
        }

        function test_lock_ignored_unless_asked() {
            tryCompare(writer, "loaded", true);
            verify(writer.set("rotationLock", 180));
            var o = make();
            wait(50);
            compare(o.rotationLocked, false);
            compare(o.screenAngle, 0);
            verify(writer.set("rotationLock", 400));
        }
    }
}
