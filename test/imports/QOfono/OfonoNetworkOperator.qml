import QtQuick 2.0

Item {
    id: ofonoConnMan
    property string operatorPath: "/dummymodem/operator/" + mcc + mnc
    readonly property string name: "LuneOperator"
    readonly property string status: "current"
    readonly property string mcc: "123"
    readonly property string mnc: "01"
    readonly property var technologies: ["gsm", "umts", "lte"]
    readonly property string additionalInfo: ""
    readonly property bool registering: false
}
