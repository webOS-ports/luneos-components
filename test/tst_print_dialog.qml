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
import QtTest
import LuneOS.Components 1.0

/*
 * PrintDialog against a stand-in for com.palm.printmgr, which answers as
 * luneos-print-adapter did on a device with one network printer:
 *   QT_QUICK_CONTROLS_STYLE=QtQuick.Controls.LuneOS \
 *   qmltestrunner -import modules -import test/imports -input test/tst_print_dialog.qml
 */
Item {
    id: root
    width: 480
    height: 800

    readonly property string pm: "luna://com.palm.printmgr/"

    // method -> reply object, function(params) giving one, { busError: text },
    // or { hold: true } to keep the answer back (answer() sends it).
    property var replies: ({})
    property var calls: []
    // method -> the callbacks of its subscriptions still open
    property var subscribers: ({})
    property var held: []

    function _reply(uri, params, onReply, onError) {
        var method = uri.indexOf(pm) === 0 ? uri.substring(pm.length) : uri;
        var r = replies[method];
        if (typeof r === "function")
            r = r(params);
        if (r === undefined)
            r = { returnValue: true };
        if (r.hold) {
            held.push({ method: method, onReply: onReply, onError: onError });
            return;
        }
        if (r.busError !== undefined)
            onError(r.busError);
        else
            onReply({ payload: JSON.stringify(r) });
    }

    function fakeCall(uri, json, onReply, onError) {
        var params = JSON.parse(json);
        calls.push({ uri: uri, params: params });
        _reply(uri, params, onReply, onError);
    }

    function fakeSubscribe(uri, json, onReply, onError) {
        var params = JSON.parse(json);
        calls.push({ uri: uri, params: params });
        var method = uri.substring(pm.length);
        var entry = { onReply: onReply, cancelled: false };
        var list = subscribers[method] || [];
        list.push(entry);
        subscribers[method] = list;
        _reply(uri, params, onReply, onError);
        return { cancel: function() { entry.cancelled = true; } };
    }

    // A later event on the subscriptions to method still open; how many got it.
    function push(method, event) {
        var n = 0;
        (subscribers[method] || []).forEach(function(s) {
            if (!s.cancelled) {
                s.onReply({ payload: JSON.stringify(Object.assign({ returnValue: true }, event)) });
                n++;
            }
        });
        return n;
    }

    function openSubscriptions(method) {
        return (subscribers[method] || []).filter(function(s) { return !s.cancelled; }).length;
    }

    // Sends the answer held back for method.
    function answer(method, reply) {
        for (var i = 0; i < held.length; i++) {
            if (held[i].method === method) {
                var h = held.splice(i, 1)[0];
                h.onReply({ payload: JSON.stringify(Object.assign({ returnValue: true }, reply)) });
                return;
            }
        }
        throw new Error("nothing held for " + method);
    }

    function callsTo(method) {
        return calls.filter(function(c) { return c.uri === pm + method; });
    }

    readonly property var office: ({ printerID: "Office_Printer", printerName: "Office Printer",
                                     printerAddress: "Office Printer._ipps._tcp.local", source: "fromZeroconf" })
    // printers/getCapabilities as the adapter answered for that printer
    readonly property var officeCaps: ({ returnValue: true, canDuplex: true, canPrintBorderless: false,
        mediaType: ["Plain", "Brochure Matte"], canPrintQualityHigh: true, isSupported: true,
        trays: ["Auto", "Manual", "Tray1"], hasPhotoTray: false, hasFaceDownTray: false,
        canPrintQualityDraft: true, mediaSize: ["ISO_A4", "ISO_A6", "US_Legal", "US_Letter", "HAGAKI"],
        hasColor: true, canPrintQualityNormal: true, canGrayscale: true, canCancel: true })

    PrintDialog {
        id: dialog
        appName: "Test"
        duplexOption: true
        colorOption: true
        call: root.fakeCall
        subscribe: root.fakeSubscribe
        hideProgressDelay: 0
        searchTimeout: 300
    }

    SignalSpy { id: finished; target: dialog; signalName: "finished" }

    TestCase {
        name: "PrintDialog"
        when: windowShown

        function init() {
            dialog.close();
            // A failure's message stays until it is closed
            var message = findChild(root, "printMessage");
            if (message && message.visible)
                message.close();
            dialog.images = false;
            dialog.mediaSizeOption = false;
            dialog.margin = {};
            dialog.copiesRange = { min: 1, max: 25 };
            dialog.localPaper = "ISO_A4";
            root.replies = {
                "printers/getCurrent": { returnValue: true, printerID: "", printerName: "", printerAddress: "" },
                "printers/list": { returnValue: true, subscribed: true },
                "printers/getCapabilities": root.officeCaps,
                "jobs/open": { returnValue: true, jobID: 7, subscribed: true },
                "jobs/getStatus": { returnValue: true, subscribed: true }
            };
            root.calls = [];
            root.subscribers = {};
            root.held = [];
            finished.clear();
        }

        function find(name) {
            var item = findChild(root, name);
            verify(item, name + " is there");
            return item;
        }

        function tap(name) {
            var item = find(name);
            verify(item.visible, name + " is shown");
            // The options scroll, as Enyo's did: bring the row into the group first
            var options = find("printerOptions");
            if (options.visible && options.contentItem.mapFromItem(item, 0, 0).y !== undefined) {
                var y = options.contentItem.mapFromItem(item, 0, 0).y;
                if (y < options.contentY || y + item.height > options.contentY + options.height)
                    options.contentY = Math.max(0, Math.min(y, options.contentHeight - options.height));
            }
            mouseClick(item);
        }

        // Opens the dialog on path with the office printer listed.
        function openWithPrinter(path) {
            verify(dialog.open(path || "/media/internal/docs/Report.pdf"));
            compare(root.push("printers/list", Object.assign({ eventType: "Add" }, root.office)), 1);
        }

        function chooseOffice() {
            openWithPrinter();
            tap("printer_Office_Printer");
            compare(dialog.view, "printerOptions");
        }

        function test_locatingPrinters() {
            verify(dialog.open("/media/internal/a.pdf"));
            verify(find("printDialog").visible);
            compare(dialog.title, "Print");
            compare(find("searchMessage").text, "Locating Printers...");
            verify(!find("printDialogPrint").enabled);
            compare(root.callsTo("printers/getCurrent").length, 1);
            compare(root.callsTo("printers/list")[0].params, { subscribe: true });
            // Nothing found in time
            tryCompare(find("searchMessage"), "text", "No printers are currently available.");
            verify(find("addPrinterButton").visible);
        }

        function test_selectAPrinter() {
            openWithPrinter();
            compare(dialog.title, "Select a Printer");
            verify(find("printerList").visible);
            verify(!find("printDialogPrint").enabled);

            tap("printer_Office_Printer");
            compare(dialog.title, "Print");
            compare(find("selectedPrinterName").text, "Office Printer");
            // The one used next time
            compare(root.callsTo("printers/setCurrent")[0].params, { printerID: "Office_Printer" });
            compare(root.callsTo("printers/getCapabilities")[0].params, { printerID: "Office_Printer" });
            verify(find("copiesPicker").visible);
            verify(find("duplexSwitch").visible);
            verify(find("colorSwitch").visible);
            verify(!find("duplexSwitch").checked);
            verify(find("colorSwitch").checked);
            // Not asked for
            verify(!find("sizePicker").visible);
            verify(find("printDialogPrint").enabled);

            tap("selectAnotherPrinterButton");
            compare(dialog.view, "printerSelector");
        }

        function test_theLastPrinterStraightAway() {
            root.replies["printers/getCurrent"] = Object.assign({ returnValue: true }, root.office);
            verify(dialog.open("/media/internal/a.pdf"));
            compare(dialog.view, "printerOptions");
            compare(dialog.selectedPrinter.id, "Office_Printer");
            // Already the current one
            compare(root.callsTo("printers/setCurrent").length, 0);
        }

        function test_optionsThePrinterHasNot() {
            root.replies["printers/getCapabilities"] = Object.assign({}, root.officeCaps, { canDuplex: false, hasColor: false });
            chooseOffice();
            verify(!find("duplexSwitch").visible);
            verify(!find("colorSwitch").visible);
            verify(find("copiesPicker").visible);
            dialog.copiesRange = { min: 1, max: 1 };
            verify(!find("copiesPicker").visible);
        }

        function test_capabilitiesFail() {
            root.replies["printers/getCapabilities"] = { returnValue: false, errorCode: -406 };
            chooseOffice();
            compare(find("capabilitiesMessage").text,
                    "Unable to communicate with the printer. Please make sure the printer is online and try again.");
            verify(!find("printDialogPrint").enabled);
        }

        function test_aPrinterGoes() {
            openWithPrinter();
            root.push("printers/list", { eventType: "Rmv", printerID: "Office_Printer" });
            compare(dialog.printers.length, 0);
            compare(dialog.title, "Print");
        }

        function test_printsADocument() {
            chooseOffice();
            find("copiesPicker").activated(1);
            tap("duplexSwitch");
            tap("colorSwitch");
            tap("printDialogPrint");
            verify(!find("printDialog").visible);
            // The printer list is let go
            compare(root.openSubscriptions("printers/list"), 0);

            var launch = root.calls.filter(function(c) { return c.uri === "luna://com.palm.applicationManager/open"; });
            compare(launch.length, 1);
            compare(launch[0].params, { id: "org.webosports.app.settings.printmanager",
                                        params: { "$disableCardPreLaunch": true, runHeadless: true } });
            compare(root.callsTo("jobs/open")[0].params, { subscribe: true, printerID: "Office_Printer",
                                                           description: "Report.pdf", appName: "Test" });
            compare(root.callsTo("jobs/editPrintParams")[0].params, { jobID: 7, numCopies: 2, duplex: "Book",
                                                                      color: "Mono", autoScale: true, mediaSize: "ISO_A4" });
            compare(root.callsTo("jobs/getFinalParamsAndArea")[0].params, { jobID: 7 });
            compare(root.callsTo("jobs/getStatus").length, 1);
            compare(root.callsTo("jobs/addFile")[0].params, { jobID: 7, pathName: "/media/internal/docs/Report.pdf",
                                                              currentPage: 1, totalPages: 1 });
            compare(root.callsTo("jobs/close")[0].params, { jobID: 7 });
            compare(finished.count, 1);
            compare(finished.signalArguments[0][0], "success");
            verify(!dialog.printing);
            verify(!find("printProgress").visible);
            compare(root.openSubscriptions("jobs/getStatus"), 0);
            compare(root.openSubscriptions("jobs/open"), 0);
        }

        function test_progressWhileItGoes() {
            root.replies["jobs/getFinalParamsAndArea"] = { hold: true };
            chooseOffice();
            tap("printDialogPrint");
            verify(dialog.printing);
            verify(find("printProgress").visible);
            compare(find("printProgress").title, "Preparing to print...");
            compare(find("printProgressBar").value, 2);
            // Not a second dialog meanwhile
            verify(!dialog.open("/media/internal/b.pdf"));
            root.answer("jobs/getFinalParamsAndArea", { pixelUnits: 300 });
            compare(finished.count, 1);
        }

        function test_theProgressStaysAMoment() {
            dialog.hideProgressDelay = 200;
            chooseOffice();
            tap("printDialogPrint");
            compare(root.callsTo("jobs/close").length, 1);
            verify(find("printProgress").visible);
            compare(finished.count, 0);
            tryCompare(finished, "count", 1);
            verify(!find("printProgress").visible);
            dialog.hideProgressDelay = 0;
        }

        function test_printsPictures() {
            dialog.images = true;
            dialog.mediaSizeOption = true;
            root.replies["printers/getCapabilities"] = Object.assign({}, root.officeCaps, {
                canPrintBorderless: true, mediaType: ["Plain", "Photo"],
                mediaSize: ["ISO_A4", "Photo_4x6", "Photo_5x7"] });
            verify(dialog.open(["/media/internal/DCIM/a.jpg", "/media/internal/DCIM/b.png"], "Holiday"));
            root.push("printers/list", Object.assign({ eventType: "Add" }, root.office));
            tap("printer_Office_Printer");
            var sizes = find("sizePicker");
            verify(sizes.visible);
            compare(sizes.currentText, "10x15cm");
            compare(dialog.mediaSizes.map(function(s) { return s.text; }), ["A4", "10x15cm", "13x18cm"]);
            tap("printDialogPrint");
            compare(root.callsTo("jobs/open")[0].params.description, "Holiday");
            compare(root.callsTo("jobs/editPrintParams")[0].params, { jobID: 7, numCopies: 1, mediaSize: "Photo_4x6",
                duplex: "None", color: "Color", autoScale: true, autoRotate: true, borderless: true,
                mediaType: "Photo", printQuality: "Best" });
            var added = root.callsTo("jobs/addFile").map(function(c) { return c.params; });
            compare(added, [{ jobID: 7, pathName: "/media/internal/DCIM/a.jpg", currentPage: 1, totalPages: 2 },
                            { jobID: 7, pathName: "/media/internal/DCIM/b.png", currentPage: 2, totalPages: 2 }]);
            compare(finished.signalArguments[0][0], "success");
        }

        function test_picturesOnAnOfficePrinter() {
            // Plain paper only, no borderless: none of the photo settings
            dialog.images = true;
            dialog.mediaSizeOption = true;
            chooseOffice();
            compare(find("sizePicker").currentText, "A4");
            tap("printDialogPrint");
            var p = root.callsTo("jobs/editPrintParams")[0].params;
            compare(p.mediaSize, "ISO_A4");
            verify(p.mediaType === undefined);
            verify(p.borderless === undefined);
            compare(p.printQuality, "Best");
        }

        function test_insetsWhenAsked() {
            dialog.margin = { top: 0.5, left: 0.25 };
            dialog.localPaper = "US_Letter";
            chooseOffice();
            tap("printDialogPrint");
            var p = root.callsTo("jobs/editPrintParams")[0].params;
            compare(p.topInset, 0.5);
            compare(p.leftInset, 0.25);
            verify(p.rightInset === undefined);
            compare(p.mediaSize, "US_Letter");
        }

        function test_aJobThatFails() {
            root.replies["jobs/editPrintParams"] = { returnValue: false, errorCode: -238 };
            chooseOffice();
            tap("printDialogPrint");
            compare(root.callsTo("jobs/close")[0].params, { jobID: 7 });
            compare(root.callsTo("jobs/addFile").length, 0);
            compare(finished.signalArguments[0][0], "failure");
            var text = "This printer is currently not supported.  Please select or add another printer.";
            compare(finished.signalArguments[0][1], text);
            verify(find("printMessage").visible);
            compare(find("printMessageText").text, text);
            tap("printMessageClose");
            verify(!find("printMessage").visible);
        }

        function test_aJobThatCannotOpen() {
            root.replies["jobs/open"] = { returnValue: false, errorCode: -243 };
            chooseOffice();
            tap("printDialogPrint");
            // No job to close
            compare(root.callsTo("jobs/close").length, 0);
            compare(finished.signalArguments[0][1],
                    "The printer queue is currently full. Please wait for a print job to finish before you start a new one. (error -243)");
        }

        function test_aPageTheJobRefusesWaitsForThePrinter() {
            root.replies["jobs/addFile"] = { returnValue: false, errorCode: -703 };
            chooseOffice();
            tap("printDialogPrint");
            compare(root.callsTo("jobs/close").length, 0);
            verify(dialog.printing);
            // The printer gives up on it; what went wrong first is what is said
            root.push("jobs/getStatus", { jobID: 7, printerState: "DONE", jobStatus: "Error" });
            compare(root.callsTo("jobs/close").length, 1);
            compare(finished.signalArguments[0][1], "Unable to process print job. (error -703)");
        }

        function test_cancelledFromElsewhere() {
            root.replies["jobs/close"] = { hold: true };
            root.replies["jobs/addFile"] = { returnValue: false, errorCode: -219 };
            chooseOffice();
            tap("printDialogPrint");
            // Another job's news is not this one's
            root.push("jobs/getStatus", { jobID: 8, printerState: "DONE", jobStatus: "Cancelled" });
            compare(root.callsTo("jobs/close").length, 0);
            root.push("jobs/getStatus", { jobID: 7, printerState: "DONE", jobStatus: "Cancelled" });
            root.answer("jobs/close", {});
            compare(finished.signalArguments[0][0], "cancel");
            verify(!find("printMessage").visible);
        }

        function test_cancelWhileItOpens() {
            root.replies["jobs/open"] = { hold: true };
            chooseOffice();
            tap("printDialogPrint");
            tap("printProgressCancel");
            compare(find("printProgress").title, "Canceling print job...");
            verify(!find("printProgressCancel").enabled);
            root.answer("jobs/open", { jobID: 9, subscribed: true });
            compare(root.callsTo("jobs/cancel")[0].params, { jobID: 9 });
            compare(root.callsTo("jobs/editPrintParams").length, 0);
            compare(finished.signalArguments[0][0], "cancel");
            verify(!find("printProgress").visible);
        }

        function test_cancelAJob() {
            root.replies["jobs/addFile"] = { hold: true };
            chooseOffice();
            tap("printDialogPrint");
            tap("printProgressCancel");
            compare(root.callsTo("jobs/cancel")[0].params, { jobID: 7 });
            compare(finished.signalArguments[0][0], "cancel");
        }

        function test_addAPrinter() {
            openWithPrinter();
            tap("addPrinterRowButton");
            compare(dialog.title, "Add a Printer");
            compare(find("printDialogPrint").text, "Done");
            verify(!find("printDialogPrint").enabled);
            find("printerAddressField").text = "192.168.1.50";
            find("printerNameField").text = "Office MFP";
            verify(find("printDialogPrint").enabled);
            tap("printDialogPrint");
            compare(root.callsTo("printers/add")[0].params,
                    { printerID: "192.168.1.50", printerName: "Office MFP", printerAddress: "192.168.1.50" });
            compare(dialog.view, "printerOptions");
            compare(find("selectedPrinterName").text, "Office MFP");
        }

        function test_aPrinterThatCannotBeAdded() {
            root.replies["printers/add"] = { returnValue: false, errorCode: -206 };
            openWithPrinter();
            tap("addPrinterRowButton");
            find("printerAddressField").text = "printer.local";
            tap("printDialogPrint");
            compare(dialog.view, "printerAdder");
            compare(find("printMessageText").text,
                    "The IP address for the printer is not valid. Check the address, then re-enter it.");
            tap("printMessageClose");
            // Cancel goes back to the printers, and again closes the dialog
            tap("printDialogCancel");
            compare(dialog.view, "printerSelector");
            tap("printDialogCancel");
            verify(!dialog.isOpen);
        }

        function test_back() {
            openWithPrinter();
            tap("addPrinterRowButton");
            verify(dialog.back());
            compare(dialog.view, "printerSelector");
            verify(dialog.back());
            verify(!dialog.isOpen);
            verify(!dialog.back());
        }

        function test_withoutTheService() {
            root.replies["printers/getCurrent"] = { busError: "Service does not exist: com.palm.printmgr." };
            root.replies["printers/list"] = { busError: "Service does not exist: com.palm.printmgr." };
            verify(dialog.open("/media/internal/a.pdf"));
            tryCompare(find("searchMessage"), "text", "No printers are currently available.");
        }
    }
}
