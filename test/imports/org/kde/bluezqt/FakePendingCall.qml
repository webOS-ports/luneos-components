import QtQuick

/*
 * BluezQt's PendingCall: "error" is 0 (NoError) on success. The test
 * finishes it with finish().
 */
QtObject {
    property int error: 0
    property string errorText: ""

    signal finished(var call)

    function finish(err) {
        error = err || 0;
        finished(this);
    }
}
