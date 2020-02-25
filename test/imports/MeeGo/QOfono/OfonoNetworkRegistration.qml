import QtQuick 2.0

Item {
    id: ofonoNetworkRegistration

    property string name: "Stub Network"
    property string modemPath
    signal scanError
    readonly property variant networkOperators: ["LuneOperator"]
    readonly property string currentOperatorPath: ""
    readonly property string mode: "auto"
    readonly property string technology: "umts"
    readonly property string status: "registered"
    readonly property int strength: 40
}
