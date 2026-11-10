/*
 * Shared state for the network-scan and APN halves of the QOfono desktop
 * mock. OfonoNetworkRegistration/OfonoNetworkOperator and OfonoConnMan/
 * OfonoContextConnection are each a pair of otherwise-independent mock
 * Items - a scan result or an APN edit made through one has to be visible to
 * every other instance bound to the same path, the way it would be over the
 * real oFono D-Bus, so the data and the current selection live here instead
 * of on any one of them.
 */
.pragma library

// org.ofono.NetworkRegistration's Mode property: "auto" or "manual".
var mode = "auto";

var operators = [
    { path: "/mock/modem0/operator/20404", name: "KPN", status: "available",
      mcc: "204", mnc: "04", technologies: ["gsm", "umts", "lte"] },
    { path: "/mock/modem0/operator/20408", name: "Vodafone", status: "current",
      mcc: "204", mnc: "08", technologies: ["gsm", "umts", "lte"] },
    { path: "/mock/modem0/operator/20416", name: "T-Mobile", status: "forbidden",
      mcc: "204", mnc: "16", technologies: ["gsm", "umts"] }
];

var registrationListeners = [];

function operatorByPath(path) {
    for (var i = 0; i < operators.length; i++)
        if (operators[i].path === path)
            return operators[i];
    return null;
}

function currentOperator() {
    for (var i = 0; i < operators.length; i++)
        if (operators[i].status === "current")
            return operators[i];
    return null;
}

function _notifyRegistration() {
    for (var i = 0; i < registrationListeners.length; i++)
        registrationListeners[i]();
}

// Manual pick from a scan (registerOperator()), or oFono's own Register()
// call falling back to whatever it likes automatically - the mock just
// keeps the same current operator rather than picking a new one.
function selectOperator(path, manual) {
    var picked = operatorByPath(path);
    if (!picked)
        return;
    for (var i = 0; i < operators.length; i++)
        operators[i].status = (operators[i].path === path) ? "current" : "available";
    mode = manual ? "manual" : "auto";
    _notifyRegistration();
}

function goAutomatic() {
    mode = "auto";
    _notifyRegistration();
}

// APN contexts, one org.ofono.ConnectionContext per entry.
var contexts = [
    { path: "/mock/modem0/context1", accessPointName: "internet", name: "Internet",
      type: "internet", username: "", password: "", protocol: "ip",
      authMethod: "none", active: true, messageCenter: "", messageProxy: "" },
    { path: "/mock/modem0/context2", accessPointName: "mms.internet", name: "MMS",
      type: "mms", username: "", password: "", protocol: "ip",
      authMethod: "none", active: false,
      messageCenter: "http://mms.example.com/mms", messageProxy: "10.0.0.1:8080" }
];

// The next AddContext/RemoveContext fails with this message instead, the
// way ofono answers with org.ofono.Error.* (a test sets it, one shot).
var failNextContextCall = "";
var _nextContextId = 3;

// org.ofono.ConnectionManager.AddContext: a new, inactive context of the
// given type with ofono's defaults. Returns its path, or "" on failure.
function addContext(type) {
    if (failNextContextCall !== "")
        return "";
    var path = "/mock/modem0/context" + _nextContextId++;
    contexts.push({ path: path, accessPointName: "", name: "", type: type,
                    username: "", password: "", protocol: "ip",
                    authMethod: "chap", active: false,
                    messageCenter: "", messageProxy: "" });
    return path;
}

// org.ofono.ConnectionManager.RemoveContext: ofono deactivates an active
// context first, so removal does not depend on it. Returns success.
function removeContext(path) {
    if (failNextContextCall !== "")
        return false;
    for (var i = 0; i < contexts.length; i++) {
        if (contexts[i].path === path) {
            contexts.splice(i, 1);
            return true;
        }
    }
    return false;
}

function contextByPath(path) {
    for (var i = 0; i < contexts.length; i++)
        if (contexts[i].path === path)
            return contexts[i];
    return null;
}
