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
 * A stand-in for the application list SAM answers listApps with.
 *
 * Each entry is that application's appinfo.json plus the two fields SAM works
 * out for itself and puts back into it: "systemApp", and "removable", which
 * it forces to false for anything it considers a system app. A page asks
 * rather than deciding for itself which of the two an application is, so the
 * mock has to carry both, and has to carry a mix - all-removable or
 * all-system would leave half of any such page untested.
 *
 * Invisible entries are in here for the same reason: on a real device a good
 * half of what is installed is a service or a piece of the shell that the
 * launcher never shows, which is exactly why a list of applications needs
 * somewhere to hide them.
 */
var apps = [
    {
        "id": "com.palm.app.browser", "title": "Browser", "version": "3.0.0",
        "type": "web", "vendor": "Palm", "visible": true,
        "systemApp": true, "removable": false,
        "requiredPermissions": ["networkconnection.query", "database.operation"]
    },
    {
        "id": "org.webosports.app.phone", "title": "Phone", "version": "0.9.1",
        "type": "qml", "vendor": "WebOS Ports", "visible": true,
        "systemApp": true, "removable": false,
        "requiredPermissions": ["telephony.management", "audio.operation",
                                "contacts.operation"]
    },
    {
        "id": "org.webosports.app.settings.wifi", "title": "Wi-Fi",
        "version": "0.4.0", "type": "qml", "vendor": "WebOS Ports",
        "visible": true, "systemApp": true, "removable": false,
        "requiredPermissions": ["wifi.query", "wifi.management"]
    },
    {
        "id": "org.webosports.app.memos", "title": "Memos", "version": "0.7.0",
        "type": "qml", "vendor": "WebOS Ports", "visible": true,
        "systemApp": false, "removable": true,
        "requiredPermissions": ["database.operation"]
    },
    {
        "id": "org.webosports.app.preware", "title": "Preware",
        "version": "1.9.4", "type": "web", "vendor": "WebOS Internals",
        "visible": true, "systemApp": false, "removable": true,
        "requiredPermissions": ["ipkg-service.operation",
                                "applicationinstall.management"]
    },
    {
        "id": "org.webosports.app.terminal", "title": "Terminal",
        "version": "0.3.2", "type": "qml", "vendor": "WebOS Ports",
        "visible": true, "systemApp": false, "removable": true,
        "requiredPermissions": []
    },
    {
        "id": "com.webos.app.notification", "title": "Notification",
        "version": "1.0.0", "type": "web", "vendor": "LG Electronics",
        "visible": false, "systemApp": true, "removable": false,
        "requiredPermissions": ["notification.management"]
    },
    {
        "id": "com.webos.surfacemanager", "title": "Surface Manager",
        "version": "1.0.0", "type": "native", "vendor": "LG Electronics",
        "visible": false, "systemApp": true, "removable": false,
        "requiredPermissions": ["luna-sysmgr.operation", "display.operation"]
    }
];

var listSubscribers = [];

function listPayload() {
    return { "returnValue": true, "subscribed": true, "apps": apps };
}

function addListSubscriber(returnFct) {
    listSubscribers.push(returnFct);
}

function postList() {
    var payload = { "payload": JSON.stringify(listPayload()) };
    for (var i = 0; i < listSubscribers.length; i++)
        listSubscribers[i](payload);
}

/* Mirrors appinstalld: it refuses anything SAM marked unremovable rather
 * than letting a page find out by the entry not going away. */
function remove(appId) {
    for (var i = 0; i < apps.length; i++) {
        if (apps[i].id !== appId)
            continue;

        if (!apps[i].removable)
            return { "returnValue": false, "errorText": "not removable" };

        apps.splice(i, 1);
        postList();
        return { "returnValue": true };
    }

    return { "returnValue": false, "errorText": "no such application" };
}
