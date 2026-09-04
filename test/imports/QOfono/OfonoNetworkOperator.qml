import QtQuick 2.0

import "ofonomock.js" as OfonoMock

/// Desktop mock of QOfonoNetworkOperator: one row of a manual network scan,
/// bound by operatorPath the way the real object is looked up under a
/// NetworkRegistration's networkOperators paths.
Item {
    id: op

    property string operatorPath: ""
    property string name: "LuneOS Mock"
    property string status: "current"
    property string mcc: ""
    property string mnc: ""
    property var technologies: []
    property string additionalInfo: ""
    property bool registering: false

    function _refresh() {
        var found = OfonoMock.operatorByPath(operatorPath);
        if (!found)
            return;
        name = found.name;
        status = found.status;
        mcc = found.mcc;
        mnc = found.mnc;
        technologies = found.technologies;
    }

    onOperatorPathChanged: _refresh()
    Component.onCompleted: {
        _refresh();
        OfonoMock.registrationListeners.push(_refresh);
    }

    function registerOperator() {
        registering = true;
        Qt.callLater(function() {
            OfonoMock.selectOperator(operatorPath, true);
            registering = false;
        });
    }
}
