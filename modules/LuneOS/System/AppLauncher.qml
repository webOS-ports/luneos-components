/*
 * (c) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import LuneOS.Service 1.0

import "Services.js" as Services

/*
 * Starts another application, or hands a URL to whatever opens it.
 *
 *     AppLauncher { id: launcher }
 *     onClicked: launcher.launch("org.webosports.app.photos", { "album": "Camera" })
 *     onLinkActivated: (link) => launcher.open(link)
 *
 * The apps had six copies of this, under three names for the application
 * manager. Both functions take optional callbacks: done(response) once the
 * manager has accepted the request, failed(errorText) if it refused it.
 *
 * The calling app needs the ACG groups for it in its appinfo.json's
 * requiredPermissions: "application.launcher" to launch, and
 * "appmanager.management" to open. Without them the bus refuses the call
 * ("Denied method call") and failed() says so - Camera, for one, has
 * neither, and Remote and Date & Time were refused both on the Q25.
 */
QtObject {
    id: launcher

    // The name to call the manager as. Empty means the application's own.
    property alias clientName: service.name

    function launch(appId, params, done, failed) {
        var request = { "id": appId };
        if (params !== undefined && params !== null)
            request.params = params;
        _send(Services.applicationManager, "/launch", request, done, failed);
    }

    // Hands a URL (or a file, or a mailto:) to the application registered
    // for it. Not on the OSE application manager, which has no "open".
    //
    // The older manager answers a successful open with returnValue false
    // and an empty errorText: on the Q25 it started the browser for a web
    // address and still said {"returnValue": false, "errorText": ""}. A real
    // refusal always says why ("Provide a valid "id" or "target" field",
    // "Denied method call"), so only an empty reason counts as done.
    function open(target, done, failed) {
        _send(Services.resourceHandler, "/open", { "target": target }, done, failed, true);
    }

    function _send(manager, method, request, done, failed, emptyErrorIsDone) {
        service.call(manager + method, JSON.stringify(request),
                     function (message) {
                         var response = JSON.parse(message.payload);
                         if (response.returnValue === false
                                 && !(emptyErrorIsDone && response.errorText === "")) {
                             var why = response.errorText || (method + " failed");
                             console.warn("AppLauncher" + method + ": " + why);
                             if (failed)
                                 failed(why);
                         } else if (done) {
                             done(response);
                         }
                     },
                     function (message) {
                         var why = launcher._text(message);
                         console.warn("AppLauncher" + method + ": " + why);
                         if (failed)
                             failed(why);
                     });
    }

    function _text(message) {
        return typeof message === "string" ? message : message.payload;
    }

    property LunaService _service: LunaService {
        id: service
    }
}
