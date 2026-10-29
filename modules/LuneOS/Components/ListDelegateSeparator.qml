import QtQuick 2.0

Item {
    id: separator

    property int index: 0;
    property int count: 0;
    property bool isHorizontal: false

    property bool showSeparator: index < count - 1

    // The line and the lighter one beside it. Light lists by default; a
    // dark list sets its own, e.g. "#1a1a1a" and "#2e2e2e".
    property color lineColor: '#ADADAD'
    property color highlightColor: '#ECECEC'

    Rectangle {
        y: parent.height-1
        height: 1
        width: parent.width
        color: separator.lineColor
        visible: separator.showSeparator && !separator.isHorizontal
    }
    Rectangle {
        y: parent.height
        height: 1
        width: parent.width
        color: separator.highlightColor
        visible: separator.showSeparator && !separator.isHorizontal
    }
    Rectangle {
        x: parent.width-1
        height: parent.height
        width: 1
        color: separator.lineColor
        visible: separator.showSeparator && separator.isHorizontal
    }
    Rectangle {
        x: parent.width
        height: parent.height
        width: 1
        color: separator.highlightColor
        visible: separator.showSeparator && separator.isHorizontal
    }
}
