import QtQuick 2.0

import "ofonomock.js" as OfonoMock

/// Desktop mock of QOfonoConnectionContext: one APN, bound by contextPath.
/// Every writable property mirrors back into ofonomock.js's shared context
/// list on change, the same way assigning one on the real object issues a
/// D-Bus property Set - so an edit made through one instance (an edit popup)
/// is still there the next time a list re-reads the same contextPath.
Item {
    id: ctx

    property string contextPath: ""
    property bool active: false
    property bool provisioning: false
    property string accessPointName: ""
    property string type: "internet"
    property string authMethod: "none"
    property string username: ""
    property string password: ""
    property string protocol: "ip"
    property string name: ""
    property string messageProxy: ""
    property string messageCenter: ""
    property var settings: ({})
    property string modemPath: ""

    property bool _loading: false

    function _refresh() {
        var found = OfonoMock.contextByPath(contextPath);
        if (!found)
            return;
        _loading = true;
        active = found.active;
        accessPointName = found.accessPointName;
        type = found.type;
        authMethod = found.authMethod;
        username = found.username;
        password = found.password;
        protocol = found.protocol;
        name = found.name;
        _loading = false;
    }

    onContextPathChanged: _refresh()
    Component.onCompleted: _refresh()

    function _writeBack(field, value) {
        if (_loading)
            return;
        var found = OfonoMock.contextByPath(contextPath);
        if (found)
            found[field] = value;
    }

    onActiveChanged: _writeBack("active", active)
    onAccessPointNameChanged: _writeBack("accessPointName", accessPointName)
    onTypeChanged: _writeBack("type", type)
    onAuthMethodChanged: _writeBack("authMethod", authMethod)
    onUsernameChanged: _writeBack("username", username)
    onPasswordChanged: _writeBack("password", password)
    onProtocolChanged: _writeBack("protocol", protocol)
    onNameChanged: _writeBack("name", name)

    function disconnect() {
        active = false;
    }

    function provision() {
        return true;
    }
}
