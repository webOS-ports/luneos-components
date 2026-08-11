import QtQuick 2.0

/**
 * Desktop mock of QOfonoCallForwarding.
 *
 * Setting a property stores it and reports success on the next tick, which is
 * what the phone app's supplementary-service flow waits for, so the MMI codes
 * (**21*number#, #21#, *#21#) and the preferences page both work offline.
 */
Item {
    id: callForwarding

    property string modemPath: ""

    property string voiceUnconditional: ""
    property string voiceBusy: ""
    property string voiceNoReply: ""
    property int voiceNoReplyTimeout: 20
    property string voiceNotReachable: ""
    property bool forwardingFlagOnSim: false

    signal voiceUnconditionalComplete(bool success)
    signal voiceBusyComplete(bool success)
    signal voiceNoReplyComplete(bool success)
    signal voiceNoReplyTimeoutComplete(bool success)
    signal voiceNotReachableComplete(bool success)
    signal getPropertiesFailed()

    onVoiceUnconditionalChanged: voiceUnconditionalComplete(true)
    onVoiceBusyChanged: voiceBusyComplete(true)
    onVoiceNoReplyChanged: voiceNoReplyComplete(true)
    onVoiceNoReplyTimeoutChanged: voiceNoReplyTimeoutComplete(true)
    onVoiceNotReachableChanged: voiceNotReachableComplete(true)

    function disableAll(type) {
        if (type === "all") {
            voiceUnconditional = "";
            voiceBusy = "";
            voiceNoReply = "";
            voiceNotReachable = "";
        } else {
            voiceBusy = "";
            voiceNoReply = "";
            voiceNotReachable = "";
        }
    }
}
