import QtQuick 2.0

ListModel {
    id: technologyModel

    property string name: ""
    readonly property bool available: false
    readonly property bool connected: false
    property bool powered: false
    readonly property bool scanning: false
    property bool changesInhibited: false
    property int filter: false
}
