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

import QtQuick 2.12

import "OrientationFilter.js" as OrientationFilter

/*
 * Which way the phone is held, by the rule the shell turns the screen by
 * (OrientationFilter.js), from the accelerometer.
 *
 *     DeviceOrientation {
 *         id: tilt
 *         active: sendingOurCamera
 *         followRotationLock: true
 *         clientName: "org.webosports.app.phone"
 *     }
 *     // tilt.angle: the phone; tilt.screenAngle: the screen, which stays
 *     // put while rotation is locked.
 *
 * Angles are the shell's: 0 top up, 90 left edge up, 180 upside down, 270
 * right edge up; turns the same in quarter turns. A new orientation has to
 * hold for settleInterval before angle takes it, so swinging the phone
 * through one on the way to another does not turn anything twice.
 *
 * The accelerometer runs only while active: on Halium every sample is a
 * wakeup, so keep it to when the answer is needed (the shell: while the
 * screen is lit). It is loaded from DeviceOrientationSensor.qml, so where
 * QtSensors is not installed (a desktop test runner) this still loads,
 * available stays false and the phone counts as upright. sample() is what
 * the sensor calls, and what a test can call instead.
 *
 * With followRotationLock, the system's rotationLock preference is read
 * too: screenAngle is the locked angle while it is set, and angle
 * otherwise. The shell keeps its own lock and leaves this off.
 */
Item {
    id: orientation

    /// The accelerometer runs.
    property bool active: true
    /// How long a new orientation has to hold, in ms.
    property int settleInterval: 200
    /// Read the rotationLock preference, for screenAngle.
    property bool followRotationLock: false
    /// The name to read the preference as. Empty means the application's own.
    property string clientName: ""

    /// The phone, settled: 0, 90, 180 or 270.
    readonly property int angle: _angle
    readonly property int turns: _angle / 90
    /// The accelerometer could be loaded.
    readonly property bool available: sensorLoader.status === Loader.Ready

    /// Rotation is locked (followRotationLock only), and at which angle.
    readonly property bool rotationLocked: _lockAngle >= 0 && _lockAngle < 360
    /// The screen: the locked angle while rotation is locked, else the phone.
    readonly property int screenAngle: rotationLocked ? (Math.round(_lockAngle / 90) % 4) * 90 : _angle
    readonly property int screenTurns: screenAngle / 90

    property int _angle: 0
    property int _pending: -1
    // The preference: the locked angle in degrees, or 400 when the screen
    // turns freely (luna-next-cardshell's LunaSysAPI/Preferences.qml).
    property int _lockAngle: 400

    /// One accelerometer sample, in m/s^2 along Qt's axes.
    function sample(x, y, z) {
        var proposed = OrientationFilter.orientationFor(x, y, z, _angle);
        if (proposed === _angle) {
            _pending = -1;
            settle.stop();
        } else if (proposed !== _pending) {
            _pending = proposed;
            settle.restart();
        }
    }

    // A sample from before the sensor stopped says nothing about when it
    // starts again.
    onActiveChanged: {
        if (!active) {
            settle.stop();
            _pending = -1;
        }
    }

    Timer {
        id: settle
        interval: orientation.settleInterval
        onTriggered: {
            if (orientation._pending >= 0)
                orientation._angle = orientation._pending;
            orientation._pending = -1;
        }
    }

    Loader {
        id: sensorLoader
        active: orientation.active
        source: "DeviceOrientationSensor.qml"
    }

    Connections {
        target: sensorLoader.item
        function onSampled(x, y, z) { orientation.sample(x, y, z); }
    }

    Loader {
        id: lockLoader
        active: orientation.followRotationLock
        sourceComponent: Component {
            SystemPreferences {
                clientName: orientation.clientName
                keys: ["rotationLock"]
                onChanged: (key, value) => {
                    // Anything but an angle (a false from an older
                    // store) is no lock.
                    if (key === "rotationLock")
                        orientation._lockAngle = typeof value === "number" ? value : 400;
                }
            }
        }
        onActiveChanged: if (!active) orientation._lockAngle = 400
    }
}
