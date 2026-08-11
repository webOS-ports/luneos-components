import QtQuick 2.0

/// Desktop mock of QOfonoNetworkRegistration: registered on a fake operator.
Item {
    property string modemPath: ""
    property string status: "registered"
    property string mode: "auto"
    property string name: "LuneOS Mock"
    property string technology: "lte"
    property int strength: 78
    property string mcc: "204"
    property string mnc: "04"
    property string country: "nl"
    property string baseStation: ""
    property bool scanning: false
    property var networkOperators: []
    property string currentOperatorPath: ""

    signal scanFinished()
    signal scanError(string message)
    signal registrationFinished()
    signal registrationError(string message)

    function registration() { registrationFinished(); }
    function scan() { scanFinished(); }
}
