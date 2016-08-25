import QtQuick 2.0

Item {
    id: ofonoNetworkRegistration

    property string name: "Stub Network"
    property string modemPath
    signal scanError
    property variant networkOperators
    property string currentOperatorPath: ""
    property int mode: 0
    property string technology: "umts"
    property int status: 0
}
