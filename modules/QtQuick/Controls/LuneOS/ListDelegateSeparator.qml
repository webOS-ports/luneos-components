import QtQuick 2.0

Item {
    property int index: 0;
    property int count: 0;
    property bool isHorizontal: false

    property bool showSeparator: index < count - 1

    Rectangle {
        y: parent.height-1
        height: 1
        width: parent.width
        color: '#ADADAD'
        visible: showSeparator && !isHorizontal
    }
    Rectangle {
        y: parent.height
        height: 1
        width: parent.width
        color: '#ECECEC'
        visible: showSeparator && !isHorizontal
    }
    Rectangle {
        x: parent.width-1
        color: '#ADADAD'
        visible: showSeparator && isHorizontal
    }
    Rectangle {
        x: parent.width
        height: parent.height
        width: 1
        color: '#ECECEC'
        visible: showSeparator && isHorizontal
    }
}
