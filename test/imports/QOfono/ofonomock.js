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
      authMethod: "none", active: true },
    { path: "/mock/modem0/context2", accessPointName: "mms.internet", name: "MMS",
      type: "mms", username: "", password: "", protocol: "ip",
      authMethod: "none", active: false }
];

function contextByPath(path) {
    for (var i = 0; i < contexts.length; i++)
        if (contexts[i].path === path)
            return contexts[i];
    return null;
}
