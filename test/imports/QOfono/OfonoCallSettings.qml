import QtQuick 2.0

/// Desktop mock of QOfonoCallSettings: call waiting and caller ID restriction.
Item {
    id: callSettings

    property string modemPath: ""
    // As libqofono's: the properties have been read from oFono
    property bool ready: true

    property string hideCallerId: "default"
    property string voiceCallWaiting: "disabled"
    property string callingLinePresentation: "enabled"
    property string calledLinePresentation: "enabled"
    property string callingNamePresentation: "enabled"
    property string connectedLinePresentation: "enabled"
    property string connectedLineRestriction: "disabled"
    property string callingLineRestriction: "disabled"

    signal hideCallerIdComplete(bool success)
    signal voiceCallWaitingComplete(bool success)
    signal getPropertiesFailed()

    onHideCallerIdChanged: hideCallerIdComplete(true)
    onVoiceCallWaitingChanged: voiceCallWaitingComplete(true)
}
