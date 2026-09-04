import QtQuick 2.0

import "ofonomock.js" as OfonoMock

/// Desktop mock of QOfonoNetworkRegistration: registered on a fake operator,
/// with a working scan()/registerOperator() round trip for manual carrier
/// selection - see ofonomock.js for the shared operator list.
Item {
    id: reg

    property string modemPath: ""
    property string status: "registered"
    property string mode: OfonoMock.mode
    property string name: "LuneOS Mock"
    property string technology: "lte"
    property int strength: 78
    property string mcc: "204"
    property string mnc: "04"
    property string country: "nl"
    property string baseStation: ""
    property bool scanning: false
    property var networkOperators: []
    property string currentOperatorPath: ""

    signal scanFinished()
    signal scanError(string message)
    signal registrationFinished()
    signal registrationError(string message)

    function _refresh() {
        mode = OfonoMock.mode;
        var op = OfonoMock.currentOperator();
        if (!op)
            return;
        name = op.name;
        mcc = op.mcc;
        mnc = op.mnc;
        currentOperatorPath = op.path;
    }

    Component.onCompleted: {
        _refresh();
        OfonoMock.registrationListeners.push(_refresh);
    }

    function registration() {
        OfonoMock.goAutomatic();
        registrationFinished();
    }

    function scan() {
        scanning = true;
        Qt.callLater(function() {
            var paths = [];
            for (var i = 0; i < OfonoMock.operators.length; i++)
                paths.push(OfonoMock.operators[i].path);
            networkOperators = paths;
            scanning = false;
            scanFinished();
        });
    }
}
