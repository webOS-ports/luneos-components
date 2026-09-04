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

    function _refreshContexts() {
        var paths = [];
        for (var i = 0; i < OfonoMock.contexts.length; i++)
            paths.push(OfonoMock.contexts[i].path);
        contexts = paths;
    }

    Component.onCompleted: _refreshContexts()
}
