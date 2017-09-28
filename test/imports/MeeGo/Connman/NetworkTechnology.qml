import QtQuick 2.9

Item {
    id: networkTechnology

    readonly property string name: ""
    readonly property string type: ""
    property bool powered: false
    readonly property bool connected: false
    readonly property string path: "/"
    property int idleTimeout: 1000

    property bool tethering: false
    property string tetheringId: ""
    property string tetheringPassphrase: ""

    /// signals
    signal  scanFinished();
    signal  propertiesReady();

    /// slots
    function setPowered(powered) {
    }
    function scan() {
    }
    function setPath(path) {
    }
}
