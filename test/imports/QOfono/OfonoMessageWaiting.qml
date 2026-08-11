import QtQuick 2.0

/// Desktop mock of QOfonoMessageWaiting. The mailbox number is what makes the
/// voicemail button and the long press on 1 do something.
Item {
    property string modemPath: ""
    property bool voicemailWaiting: false
    property int voicemailMessageCount: 0
    property string voicemailMailboxNumber: "+31612001234"

    signal voicemailMailboxComplete(bool success)
    signal getPropertiesFailed()
}
