import QtQuick 2.0

Item {
    property string voiceCallPath: ""
    property string lineIdentification: ""
    property string state: "disconnected"
    // Carried over IMS (VoLTE) rather than circuit-switched
    property bool ims: false
}
