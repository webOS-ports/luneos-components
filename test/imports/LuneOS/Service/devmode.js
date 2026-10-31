/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

.pragma library

/*
 * A stand-in for org.webosports.service.devmode.
 *
 * Both flags are the strings "enabled" and "disabled", not booleans, and
 * turning developer mode off stops adb with it - the real service does that,
 * so this does too, or the panel cannot be seen behaving correctly.
 */
var status = "disabled";
var usbDebugging = "disabled";

function statusPayload() {
    return {
        "returnValue": true,
        "status": status,
        "usbDebugging": usbDebugging
    };
}

function setStatus(args) {
    if (args.status !== undefined) {
        status = args.status;
        if (status === "disabled")
            usbDebugging = "disabled";
    }
    if (args.usbDebugging !== undefined)
        usbDebugging = args.usbDebugging;

    return { "returnValue": true, "errorText": "", "errorCode": 0 };
}

/*
 * USB debugging's "Allow this computer?" and Developer Options' ssh access
 * (adbAuthRequests, respondAdbAuth, set/clearDevPassword, the authorized keys,
 * sshOverWifi). A test puts a question with ask() and reads the answers the
 * shell gave in responses. The password itself is never kept, as the real
 * service never logs it: only that one was set.
 */
var authRequest = null;
var authSubscribers = [];
var responses = [];
var passwordSet = false;
var passwordCalls = 0;
var authorizedKeys = [];
var sshWifi = false;
var revoked = 0;
// Whether the service is on the bus: a dynamic one is not until something calls it.
var running = true;
var SHELL = "com.webos.surfacemanager";

function _error(code, text) {
    return { "returnValue": false, "errorCode": code, "errorText": text };
}

function authPayload() {
    return { "returnValue": true, "subscribed": true, "request": authRequest };
}

function _notifyAuth() {
    for (var i = 0; i < authSubscribers.length; i++)
        authSubscribers[i]({ payload: JSON.stringify(authPayload()) });
}

// The service lets the shell, and only the shell, ask and answer.
function _shell(caller) {
    return typeof caller === "string" && caller.indexOf(SHELL) === 0;
}

function subscribeAuth(fn, caller) {
    running = true;
    if (!_shell(caller)) {
        fn({ payload: JSON.stringify(_error("ACCESS_DENIED", "Only the shell may do that")) });
        return;
    }
    authSubscribers.push(fn);
    fn({ payload: JSON.stringify(authPayload()) });
}

// A test's host asking: the service telling the shell about a key.
function ask(fingerprint, timeoutMs) {
    authRequest = { "fingerprint": fingerprint, "timeoutMs": timeoutMs || 60000 };
    _notifyAuth();
}

// The question going without an answer (the screen locked, adbd went).
function closeRequest() {
    authRequest = null;
    _notifyAuth();
}

function respondAdbAuth(args, caller) {
    if (!_shell(caller))
        return _error("ACCESS_DENIED", "Only the shell may do that");
    if (typeof args.allow !== "boolean")
        return _error("BAD_ARGS", "allow (and always) must be true or false");
    if (!authRequest || args.fingerprint !== authRequest.fingerprint)
        return _error("NO_SUCH_REQUEST", "No such request");
    responses.push({ "fingerprint": args.fingerprint, "allow": args.allow, "always": args.always === true });
    authRequest = null;
    _notifyAuth();
    return { "returnValue": true, "remembered": args.allow && args.always === true };
}

function setDevPassword(args) {
    passwordCalls++;
    if (status !== "enabled")
        return _error("DEVMODE_OFF", "Developer mode is off");
    if (typeof args.password !== "string" || args.password.length < 8 || args.password.length > 512)
        return _error("BAD_PASSWORD", "The password has to be 8 to 512 characters");
    passwordSet = true;
    return { "returnValue": true };
}

// Taking it away again (root back to "*"); as the service, with developer
// mode off too.
var passwordClears = 0;
function clearDevPassword() {
    passwordClears++;
    passwordSet = false;
    return { "returnValue": true };
}

// Not ssh-keygen's: the tests only need one that stays the same for a key.
function _fingerprint(b64) {
    return "SHA256:" + b64.slice(-16);
}

function addAuthorizedKey(args) {
    if (status !== "enabled")
        return _error("DEVMODE_OFF", "Developer mode is off");
    var m = /^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) ([A-Za-z0-9+\/]{16,}={0,2})(?: (.*))?$/.exec(String(args.key || "").trim());
    if (!m)
        return _error("BAD_KEY", "Not an OpenSSH public key");
    var fp = _fingerprint(m[2]);
    for (var i = 0; i < authorizedKeys.length; i++)
        if (authorizedKeys[i].fingerprint === fp)
            return { "returnValue": true, "fingerprint": fp, "added": false };
    authorizedKeys.push({ "type": m[1], "fingerprint": fp, "comment": m[3] || "" });
    return { "returnValue": true, "fingerprint": fp, "added": true };
}

function removeAuthorizedKey(args) {
    var before = authorizedKeys.length;
    authorizedKeys = authorizedKeys.filter(function(k) { return k.fingerprint !== args.fingerprint; });
    if (authorizedKeys.length === before)
        return _error("NO_SUCH_KEY", "No such key");
    return { "returnValue": true };
}

function listAuthorizedKeys() {
    return { "returnValue": true, "keys": authorizedKeys.slice() };
}

function sshOverWifi(args) {
    if (typeof args.enabled !== "boolean")
        return _error("BAD_ARGS", "enabled must be true or false");
    if (args.enabled && status !== "enabled")
        return _error("DEVMODE_OFF", "Developer mode is off");
    sshWifi = args.enabled;
    return { "returnValue": true, "sshOverWifi": sshWifi };
}

function revokeAdbKeys() {
    revoked++;
    return { "returnValue": true };
}

function getAccessStatus() {
    return { "returnValue": true, "passwordSet": passwordSet,
             "authorizedKeys": authorizedKeys.length, "sshOverWifi": sshWifi };
}

// Back to a device that has never been set up, between tests.
function resetAccess() {
    authRequest = null;
    authSubscribers = [];
    responses = [];
    passwordSet = false;
    passwordCalls = 0;
    passwordClears = 0;
    authorizedKeys = [];
    sshWifi = false;
    revoked = 0;
    running = true;
}
