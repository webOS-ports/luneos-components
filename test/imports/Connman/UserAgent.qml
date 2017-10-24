import QtQuick 2.0

Item {
    id: userAgent

    property string connectionRequestType
    property string path

    /// signals
    signal userInputRequested(string servicePath, variant /*QVariantMap*/ fields);
    signal userInputCanceled();
    signal errorReported(string servicePath, string error);
    signal browserRequested(string servicePath, string url);

    signal userConnectRequested(variant /*QDBusMessage*/ message);
    signal connectionRequest();

    /// slots
    function sendUserReply(/*QVariantMap*/ input) {
    }
    function sendConnectReply(/*QString*/ replyMessage, timeout) {
    }
}
