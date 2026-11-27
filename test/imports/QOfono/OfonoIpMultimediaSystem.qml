import QtQuick 2.0

/// Desktop mock of QOfonoIpMultimediaSystem: the modem's IMS registration.
/// Registered with voice is what a phone shows as VoLTE.
Item {
    property string modemPath: ""
    property bool ready: true
    // "disable", "enable" or "auto", as oFono's Registration
    property string registration: "auto"
    property bool registered: false
    property bool voiceCapable: false
    property bool smsCapable: false
}
