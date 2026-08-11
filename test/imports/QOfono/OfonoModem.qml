import QtQuick 2.0

/// Desktop mock of QOfonoModem. `online` is what the phone app reads as
/// "airplane mode is off", so it starts powered and online.
Item {
    property string modemPath: ""
    property bool powered: true
    property bool online: true
    property string serial: "351234567890123"
    property string manufacturer: "LuneOS"
    property string model: "Mock Modem"
    property string revision: "1.0"
    property var features: [ "sms", "sim", "net", "ussd" ]
}
