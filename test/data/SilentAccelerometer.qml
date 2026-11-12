import QtQuick

// A stand-in for DeviceOrientationSensor.qml that loads and sends nothing,
// like an accelerometer whose samples have stopped.
QtObject {
    signal sampled(real x, real y, real z)
}
