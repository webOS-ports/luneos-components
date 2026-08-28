import QtQuick 2.0

/**
 * Desktop mock of QOfonoCallBarring. The mock password is "0000"; anything
 * else is refused, so the failure path is reachable without a network.
 */
Item {
    id: callBarring

    property string modemPath: ""
    property string voiceIncoming: ""
    property string voiceOutgoing: ""

    property string mockPassword: "0000"

    signal voiceIncomingComplete(bool success)
    signal voiceOutgoingComplete(bool success)
    signal changePasswordComplete(bool success)
    signal disableAllComplete(bool success)
    signal disableAllIncomingComplete(bool success)
    signal disableAllOutgoingComplete(bool success)
    signal getPropertiesFailed()

    function setVoiceIncoming(barrings, password) {
        if (password !== mockPassword) { voiceIncomingComplete(false); return; }
        voiceIncoming = (barrings === "disabled") ? "" : barrings;
        voiceIncomingComplete(true);
    }

    function setVoiceOutgoing(barrings, password) {
        if (password !== mockPassword) { voiceOutgoingComplete(false); return; }
        voiceOutgoing = (barrings === "disabled") ? "" : barrings;
        voiceOutgoingComplete(true);
    }

    function changePassword(oldPassword, newPassword) {
        if (oldPassword !== mockPassword) { changePasswordComplete(false); return; }
        mockPassword = newPassword;
        changePasswordComplete(true);
    }

    function disableAll(password) {
        if (password !== mockPassword) { disableAllComplete(false); return; }
        voiceIncoming = "";
        voiceOutgoing = "";
        disableAllComplete(true);
    }

    function disableAllIncoming(password) { voiceIncoming = ""; disableAllIncomingComplete(true); }
    function disableAllOutgoing(password) { voiceOutgoing = ""; disableAllOutgoingComplete(true); }
}
