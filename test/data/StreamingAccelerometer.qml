import QtQuick

// A stand-in for DeviceOrientationSensor.qml that streams upright samples,
// as the accelerometer does while it runs.
Timer {
    signal sampled(real x, real y, real z)
    interval: 20
    repeat: true
    running: true
    onTriggered: sampled(0, 9.80665, 0)
}
