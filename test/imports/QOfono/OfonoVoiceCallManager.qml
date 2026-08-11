import QtQuick 2.0

/**
 * Desktop mock of QOfonoVoiceCallManager.
 *
 * The phone app only reads emergencyNumbers from this -- calls themselves go
 * through the nemo voicecall manager -- so that is what the mock provides.
 */
Item {
    property string modemPath: ""
    property var emergencyNumbers: [ "112", "911", "999", "08", "000", "110", "118", "119" ]
    property string errorMessage: ""

    signal callAdded(string call)
    signal callRemoved(string call)
    signal dialComplete(bool status)

    function getCalls() { return []; }
    function dial(number, calleridHide) { dialComplete(true); }
    function hangupAll() {}
    function sendTones(tones) {}
}
