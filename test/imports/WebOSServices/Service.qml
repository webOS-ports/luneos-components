import QtQuick 2.0

/*
 * Stand-in for WebOSServices' Service, the luna-service2 handle that
 * luna-surfacemanager's webosserviceplugin provides. There is no bus here, so
 * a call only hands back a token and nothing ever answers it - except
 * registerServerStatus(), which says the service is up, so that code waiting
 * for that goes on to make its calls.
 *
 * A test that wants an answer emits response() itself, with the token the
 * call returned.
 */
QtObject {
    id: service

    property string appId
    property string service
    property string method
    property string sessionId

    signal response(string method, string payload, int token)

    property int _lastToken: 0

    function call(serviceUri, methodName, payload) {
        return ++_lastToken;
    }

    function callService(payload) {
        return ++_lastToken;
    }

    function registerServerStatus(serviceName) {
        var token = ++_lastToken;
        Qt.callLater(function () {
            service.response("signal/registerServerStatus", '{"connected":true}', token);
        });
        return token;
    }

    function cancel(token) {
    }
}
