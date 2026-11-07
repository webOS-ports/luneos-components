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
 * Printer against a stand-in for com.palm.printmgr:
 *   qmltestrunner -import modules -import test/imports -input test/tst_printer.qml
 */
Item {
    id: root
    width: 480
    height: 800

    // uri -> reply object, or { busError: text } for a call that fails.
    property var replies: ({})
    property var calls: []

    function fakeCall(uri, json, onReply, onError) {
        calls.push({ uri: uri, params: JSON.parse(json) });
        var r = replies[uri];
        if (r === undefined || r.busError !== undefined)
            onError(r === undefined ? "no reply" : r.busError);
        else
            onReply({ payload: JSON.stringify(r) });
    }

    ActionSheet { id: sheet; anchors.fill: parent }

    Printer {
        id: printer
        appName: "Test"
        call: root.fakeCall
    }

    SignalSpy { id: messages; target: printer; signalName: "message" }
    SignalSpy { id: printed; target: printer; signalName: "printed" }

    readonly property var twoPrinters: ({
        returnValue: true,
        activePrinters: [{ printerID: "p1", printerName: "Office Printer" }, { printerID: "p2" }]
    })

    TestCase {
        name: "Printer"
        when: windowShown

        function init() {
            root.replies = {};
            root.calls = [];
            messages.clear();
            printed.clear();
            sheet.hide();
        }

        function lastMessage() {
            return messages.signalArguments[messages.count - 1][0];
        }

        function test_noService() {
            root.replies = { "luna://com.palm.printmgr/printers/listActive": { busError: "no service" } };
            printer.printFile("/media/internal/a.pdf", sheet);
            compare(messages.count, 1);
            compare(lastMessage(), "Printing is not available");
            verify(!sheet.shown);
        }

        function test_noPrinters() {
            root.replies = { "luna://com.palm.printmgr/printers/listActive": { returnValue: true, activePrinters: [] } };
            printer.printFile("/media/internal/a.pdf", sheet);
            compare(lastMessage(), "No printers found");
            verify(!sheet.shown);

            root.replies = { "luna://com.palm.printmgr/printers/listActive": { returnValue: false, errorCode: -298 } };
            printer.printFile("/media/internal/a.pdf", sheet);
            compare(lastMessage(), "No printers found");
        }

        function test_offersPrintersAndSendsTheJob() {
            root.replies = {
                "luna://com.palm.printmgr/printers/listActive": root.twoPrinters,
                "luna://com.palm.printmgr/jobs/allAtOnce": { returnValue: true, jobID: 3 }
            };
            printer.printFile("/media/internal/docs/Report.pdf", sheet);
            verify(sheet.shown);
            compare(sheet.title, "Print");
            compare(sheet.subtitle, "Report.pdf");
            compare(sheet.choices.length, 2);
            compare(sheet.choices[0].label, "Office Printer");
            // A printer without a name is offered by its ID.
            compare(sheet.choices[1].label, "p2");

            sheet.choose(0);
            verify(!sheet.shown);
            compare(printed.count, 1);
            var job = root.calls[root.calls.length - 1];
            compare(job.uri, "luna://com.palm.printmgr/jobs/allAtOnce");
            compare(job.params, { printerID: "p1", description: "Report.pdf", appName: "Test",
                                  pathNames: ["/media/internal/docs/Report.pdf"], autoScale: true });
            compare(lastMessage(), "Sent to the printer");
        }

        function test_description() {
            root.replies = { "luna://com.palm.printmgr/printers/listActive": root.twoPrinters,
                             "luna://com.palm.printmgr/jobs/allAtOnce": { returnValue: true } };
            printer.printFile("/var/cache/office/x1/converted.pdf", sheet, "Letter.docx");
            compare(sheet.subtitle, "Letter.docx");
            sheet.choose(1);
            compare(root.calls[root.calls.length - 1].params.description, "Letter.docx");
            compare(root.calls[root.calls.length - 1].params.printerID, "p2");
        }

        function test_jobFails() {
            root.replies = { "luna://com.palm.printmgr/printers/listActive": root.twoPrinters,
                             "luna://com.palm.printmgr/jobs/allAtOnce": { returnValue: false, errorCode: -618,
                                                                          errorText: "unsupported or null mime type" } };
            printer.printFile("/media/internal/a.txt", sheet);
            sheet.choose(0);
            compare(lastMessage(), "Could not print: unsupported or null mime type");

            root.replies["luna://com.palm.printmgr/jobs/allAtOnce"] = { returnValue: false, errorCode: -617 };
            printer.printFile("/media/internal/a.pdf", sheet);
            sheet.choose(0);
            compare(lastMessage(), "Could not print: -617");

            root.replies["luna://com.palm.printmgr/jobs/allAtOnce"] = { busError: "service went away" };
            printer.printFile("/media/internal/a.pdf", sheet);
            sheet.choose(0);
            compare(lastMessage(), "Could not print: service went away");
        }
    }
}
