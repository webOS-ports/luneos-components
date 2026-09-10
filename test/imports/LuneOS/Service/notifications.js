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
 * A stand-in for com.webos.notification's toast settings.
 *
 * getToastSettings, and per-app enableToast/disableToast that keep what they
 * are told, are what notificationmgr gained in meta-webos-ports'
 * 0011-notificationmgr-remember-which-applications-may-not-show-a-toast. On
 * an older build the call simply does not exist, which the panel handles -
 * but the mock is written against the fixed service, because that is what
 * the panel is written against.
 *
 * Nothing is blocked to begin with, which is the state of a device nobody
 * has been through the panel on.
 */
var enabled = true;
var blockedApps = [];

function settingsPayload() {
    return {
        "returnValue": true,
        "subscribed": true,
        "enabled": enabled,
        "blockedApps": blockedApps
    };
}

var subscribers = [];

function addSubscriber(returnFct) {
    subscribers.push(returnFct);
}

function post() {
    var payload = { "payload": JSON.stringify(settingsPayload()) };
    for (var i = 0; i < subscribers.length; i++)
        subscribers[i](payload);
}

function setBlocked(appId, blocked) {
    if (!appId)
        return { "returnValue": false, "errorText": "Unknown Source ID" };

    var at = blockedApps.indexOf(appId);
    if (blocked && at < 0)
        blockedApps.push(appId);
    else if (!blocked && at >= 0)
        blockedApps.splice(at, 1);
    else
        return { "returnValue": true };

    post();
    return { "returnValue": true };
}
