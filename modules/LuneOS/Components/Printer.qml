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

import QtQuick

/*
 * Printing a file: the printers luneos-print-adapter (which serves webOS's
 * com.palm.printmgr over CUPS) knows, one picked from an ActionSheet, and the
 * file sent as one job (jobs/allAtOnce). The service takes PDF, JPEG and PNG.
 * Without the service, or without printers, it says so through message().
 *
 *     Printer {
 *         id: printer
 *         appName: "PDF"
 *         call: function(uri, json, onReply, onError) { service.call(uri, json, onReply, onError); }
 *         onMessage: function(text) { toast.show(text); }
 *     }
 *     ...
 *     printer.printFile(path, actionSheet);
 */
QtObject {
    id: printer

    // function(uri, json, onReply(message), onError(text)), as LunaService.call.
    property var call: null
    // The job's appName, which the print queue shows.
    property string appName: ""

    // A word for the user ("Sent to the printer", "No printers found").
    signal message(string text)
    // The job, as it was sent.
    signal printed(var params)

    function _name(path) {
        return path.substring(path.lastIndexOf("/") + 1);
    }

    // Offers the printers in actionSheet and prints path on the one picked.
    // description is what the queue calls the job; the file's name if not given.
    function printFile(path, actionSheet, description) {
        var title = description || _name(path);
        call("luna://com.palm.printmgr/printers/listActive", JSON.stringify({}), function(m) {
            var r = JSON.parse(m.payload);
            var list = r.returnValue ? (r.activePrinters || []) : [];
            if (list.length === 0) {
                printer.message("No printers found");
                return;
            }
            actionSheet.show("Print", list.map(function(p) {
                return { label: p.printerName || p.printerID, key: p.printerID,
                         action: function() { printer._send(path, title, p.printerID); } };
            }), title);
        }, function() {
            printer.message("Printing is not available");
        });
    }

    function _send(path, title, printerId) {
        var params = { printerID: printerId, description: title, appName: appName,
                       pathNames: [path], autoScale: true };
        printed(params);
        call("luna://com.palm.printmgr/jobs/allAtOnce", JSON.stringify(params), function(m) {
            var r = JSON.parse(m.payload);
            printer.message(r.returnValue ? "Sent to the printer" : "Could not print: " + (r.errorText || r.errorCode));
        }, function(error) {
            printer.message("Could not print: " + error);
        });
    }
}
