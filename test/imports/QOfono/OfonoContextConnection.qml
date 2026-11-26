import QtQuick 2.0

import "ofonomock.js" as OfonoMock

/// Desktop mock of QOfonoConnectionContext: one APN, bound by contextPath.
/// Every writable property mirrors back into ofonomock.js's shared context
/// list on change, the same way assigning one on the real object issues a
/// D-Bus property Set - so an edit made through one instance (an edit popup)
/// is still there the next time a list re-reads the same contextPath.
///
/// Like ofono (src/gprs.c pri_set_property), every property but Active is
/// refused while the context is active: the write is undone and reportError
/// carries ofono's org.ofono.Error.InUse message. Each write is answered with
/// setPropertyFinished, after reportError when it failed, on a later turn of
/// the event loop as a D-Bus reply would be.
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

    signal reportError(string errorString)
    signal setPropertyFinished()

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
        messageCenter = found.messageCenter || "";
        messageProxy = found.messageProxy || "";
        _loading = false;
    }

    onContextPathChanged: _refresh()
    Component.onCompleted: _refresh()

    function _writeBack(field, value) {
        if (_loading)
            return;
        var found = OfonoMock.contextByPath(contextPath);
        if (!found)
            return;
        if (found[field] === value) {
            _answer("");
            return;
        }
        if (field !== "active" && !found.active && OfonoMock.reactivateBeforeNextWrite) {
            OfonoMock.reactivateBeforeNextWrite = false;
            found.active = true;
            _loading = true;
            active = true;
            _loading = false;
        }
        if (field !== "active" && found.active) {
            _loading = true;
            ctx[field] = found[field];
            _loading = false;
            _answer("The resource is currently in use");
            return;
        }
        found[field] = value;
        _answer("");
    }

    // One answer per write, in order; Qt.callLater would fold several
    // writes made in the same turn into one.
    property var _answers: []
    function _answer(errorString) {
        _answers.push(errorString);
        answerTimer.restart();
    }
    Timer {
        id: answerTimer
        interval: 0
        onTriggered: {
            var answers = ctx._answers;
            ctx._answers = [];
            for (var i = 0; i < answers.length; i++) {
                if (answers[i] !== "")
                    ctx.reportError(answers[i]);
                ctx.setPropertyFinished();
            }
        }
    }

    onActiveChanged: _writeBack("active", active)
    onAccessPointNameChanged: _writeBack("accessPointName", accessPointName)
    onTypeChanged: _writeBack("type", type)
    onAuthMethodChanged: _writeBack("authMethod", authMethod)
    onUsernameChanged: _writeBack("username", username)
    onPasswordChanged: _writeBack("password", password)
    onProtocolChanged: _writeBack("protocol", protocol)
    onNameChanged: _writeBack("name", name)
    onMessageCenterChanged: _writeBack("messageCenter", messageCenter)
    onMessageProxyChanged: _writeBack("messageProxy", messageProxy)

    // for tests: see ofonomock.js
    function reactivateBeforeNextWrite() {
        OfonoMock.reactivateBeforeNextWrite = true;
    }

    function disconnect() {
        active = false;
    }

    function provision() {
        return true;
    }
}
