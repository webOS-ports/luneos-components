import QtQuick 2.0

import "ofonomock.js" as OfonoMock

/// Desktop mock of QOfonoConnectionManager. `contexts` is what an APN list
/// walks - see ofonomock.js and OfonoContextConnection.qml for the entries
/// themselves.
Item {
    id: connman

    property string modemPath: ""
    property bool attached: true
    property string bearer: "hspa"
    property bool suspended: false
    property bool roamingAllowed: false
    property bool powered: true
    property var contexts: []
    property string filter: ""
    property bool valid: true

    // QOfonoConnectionManager's signals; QOfonoObject's reportError carries a
    // failed call's D-Bus error message.
    signal contextAdded(string path)
    signal contextRemoved(string path)
    signal reportError(string errorString)

    // Test hook: the next addContext/removeContext fails with this message.
    function failNextContextCall(message) {
        OfonoMock.failNextContextCall = message;
    }

    // Replies come back later, as over D-Bus: the call itself returns nothing.
    function addContext(type) {
        Qt.callLater(function() {
            var path = OfonoMock.addContext(type);
            if (path === "") {
                var message = OfonoMock.failNextContextCall;
                OfonoMock.failNextContextCall = "";
                connman.reportError(message);
                return;
            }
            connman._refreshContexts();
            connman.contextAdded(path);
        });
    }

    function removeContext(path) {
        Qt.callLater(function() {
            if (!OfonoMock.removeContext(path)) {
                var message = OfonoMock.failNextContextCall || "Operation failed";
                OfonoMock.failNextContextCall = "";
                connman.reportError(message);
                return;
            }
            connman._refreshContexts();
            connman.contextRemoved(path);
        });
    }

    // libqofono's resetContexts() calls ofono's DeactivateAll, not
    // ResetContexts, so that is what this does too.
    function resetContexts() {
        Qt.callLater(function() {
            for (var i = 0; i < OfonoMock.contexts.length; i++)
                OfonoMock.contexts[i].active = false;
        });
    }

    function _refreshContexts() {
        var paths = [];
        for (var i = 0; i < OfonoMock.contexts.length; i++)
            paths.push(OfonoMock.contexts[i].path);
        contexts = paths;
    }

    Component.onCompleted: _refreshContexts()
}
