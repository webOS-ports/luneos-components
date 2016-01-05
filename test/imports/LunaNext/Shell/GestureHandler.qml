import QtQuick 2.0

Item {
    signal touchBegin 
    signal touchEnd
    signal gestureEvent(var gesture, point pos, bool timeout)

    property int timeout
    property real fingerSize
    property real minimalFlickLength
}
