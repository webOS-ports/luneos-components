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
 *
 * The accelerometer sends a steady stream while it runs (50 a second on the
 * Brax3, lying still). If that stops while active, the screen stops turning
 * with nothing to say why, until the next time the display goes off and on.
 * So when nothing has come for stallInterval the sensor is created again,
 * and that, a sensor error, and the samples coming back are logged as
 * warnings, which reach the journal.
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
    /// Create the accelerometer again when it has sent nothing for this
    /// long while active, in ms; 0 never does. Doubles, up to 30 s, while
    /// that does not bring it back.
    property int stallInterval: 2000
    /// How many times the accelerometer was created again for being silent.
    readonly property int restarts: _restarts

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

    property int _restarts: 0
    property double _lastSample: 0
    property int _stallLimit: stallInterval
    property bool _stalled: false
    property bool _reloading: false
    // The sensor's file; a test points it at one it feeds itself.
    property url _sensorSource: "DeviceOrientationSensor.qml"

    /// One accelerometer sample, in m/s^2 along Qt's axes.
    function sample(x, y, z) {
        _lastSample = Date.now();
        if (_stalled) {
            _stalled = false;
            _stallLimit = stallInterval;
            console.warn("DeviceOrientation: the accelerometer sends again");
        }
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
        active: orientation.active && !orientation._reloading
        source: orientation._sensorSource
    }

    // A silent accelerometer while active.
    Timer {
        id: stallWatch
        interval: Math.max(250, orientation.stallInterval / 2)
        repeat: true
        running: orientation.active && orientation.available && orientation.stallInterval > 0
        onRunningChanged: if (running) orientation._lastSample = Date.now()
        onTriggered: {
            var silent = Date.now() - orientation._lastSample;
            if (silent < orientation._stallLimit)
                return;
            var s = sensorLoader.item;
            console.warn("DeviceOrientation: no accelerometer sample for " + silent + " ms"
                         + (s && s.connectedToBackend !== undefined
                            ? " (connectedToBackend " + s.connectedToBackend + ", active " + s.active
                              + ", busy " + s.busy + ")" : "")
                         + "; creating it again");
            orientation._stalled = true;
            orientation._restarts++;
            orientation._stallLimit = Math.min(orientation._stallLimit * 2, 30000);
            orientation._reloading = true;
            Qt.callLater(function () { orientation._reloading = false; });
        }
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
