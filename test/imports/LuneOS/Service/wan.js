/*
 * Shared packet data state for the desktop LunaService stub.
 *
 * com.palm.wan and the radio access mode half of com.palm.telephony are read
 * through one LunaService{} and written through another - WanService.qml keeps
 * a separate mock object per method - so the state has to live in a
 * .pragma library for a set issued on one instance to reach the getstatus
 * subscription held by another, the way it does on the real bus.
 */
.pragma library

// As com.palm.wan/getstatus words them.
var networkStatus = "attached";
// none, gprs, edge, umts, hsdpa, lte, 1x, evdo
var networkType = "lte";
// "enable" means roaming is guarded against, i.e. data roaming is off.
var roamGuard = "enable";
var wanState = "enable";
var disableWan = "off";

// telephonyd radio access mode: any, gsm, umts, lte, or unknown on a modem
// with no RadioSettings interface.
var ratMode = "any";

var statusSubscribers = [];

function statusPayload() {
    return {
        "returnValue": true,
        "errorCode": 0,
        "errorText": "success",
        "simId": 0,
        "state": wanState,
        "roamguard": roamGuard,
        "networktype": networkType,
        "dataaccess": "usable",
        "networkstatus": networkStatus,
        "wanstate": wanState,
        "disablewan": disableWan,
        "connectedservices": []
    };
}

function postStatus() {
    var payload = { "payload": JSON.stringify(statusPayload()) };
    for (var i = 0; i < statusSubscribers.length; i++)
        statusSubscribers[i](payload);
}

/* Assigning a top level var of a .pragma library from QML is not reliable, so
 * every write from the mock goes through a function here, the way the dual SIM
 * state does. */
function setRatMode(mode) {
    ratMode = mode;
}

/* Mirrors what the ofono driver applies for a com.palm.wan/set. */
function applyConfiguration(args) {
    if (args.hasOwnProperty("roamguard"))
        roamGuard = (args.roamguard === "disable") ? "disable" : "enable";

    if (args.hasOwnProperty("disablewan"))
        disableWan = (args.disablewan === "on") ? "on" : "off";

    postStatus();
}
