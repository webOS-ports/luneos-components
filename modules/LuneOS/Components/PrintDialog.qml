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
import QtQuick.Controls
import QtQuick.Controls.LuneOS 2.0

import LunaNext.Common 0.1
// The platform's own dialog frame, not QtQuick.Controls' Dialog
import LuneOS.Components 1.0 as LC

/*
 * webOS's print dialog, as Enyo 1.0's PrintDialog (enyo-1.0-ports,
 * lib/printdialog) drew it on webOS 3.0.5: Select a Printer, with Add a
 * Printer, then the printer's options and Print. Its job is the one webOS
 * apps ran against com.palm.printmgr, which luneos-print-adapter serves
 * over CUPS: jobs/open, editPrintParams, getFinalParamsAndArea, one addFile
 * a file, close. "Preparing to print..." shows how far it got, with Cancel;
 * a job that fails says why in a message with Close. The Print Manager is
 * started as the job opens and shows how the printing goes.
 *
 *     PrintDialog {
 *         id: printDialog
 *         appName: "PDF"
 *         duplexOption: true
 *         colorOption: true
 *         call: appWindow.busCall          // as LunaService.call
 *         subscribe: appWindow.busSubscribe  // as LunaService.subscribe
 *     }
 *     ...
 *     printDialog.open(pdf.path);                   // a PDF
 *     printDialog.open([a.jpg, b.jpg], "Album");    // with images: true
 *
 * It covers its parent, as the other dialogs do, so it is declared at the
 * top of the page or window.
 */
Item {
    id: printDialog

    // Always there and drawing nothing itself: its dialogs come and go. (A
    // child of a hidden item is never visible, so it cannot hide itself
    // when they are shut.)
    anchors.fill: parent
    z: 1000

    // function(uri, json, onReply(message), onError(text)), as LunaService.call.
    property var call: null
    // The same, for a subscription; gives back a call that has cancel().
    property var subscribe: null
    // What the print queue shows for the job: the app, and the job's name
    // (the first file's name, unless open() is given one).
    property string appName: ""
    property string description: ""

    // The files to print: PDF, JPEG or PNG, which the print service reads.
    property var files: []
    // The files are pictures: each is a page, turned and sized to the paper
    // (Enyo's ImagePrintJob). Otherwise they are documents of their own
    // size, scaled to the paper.
    property bool images: false

    // The options offered; as in Enyo, none but the number of copies unless
    // asked for. Two-sided and colour show only where the printer has them.
    property var copiesRange: ({ min: 1, max: 25 })
    property bool duplexOption: false
    property bool colorOption: false
    property bool mediaSizeOption: false
    // Insets in inches ({ top, left, right, bottom }), when the app wants any.
    property var margin: ({})

    // The paper of the place (A4, or Letter where the measures are American).
    property string localPaper: Qt.locale().measurementSystem === Locale.MetricSystem ? "ISO_A4" : "US_Letter"
    // The Print Manager, started headless as a job opens.
    property string printManagerId: "org.webosports.app.settings.printmanager"
    // How long "Locating Printers..." waits before it says there are none.
    property int searchTimeout: 10000
    // How long the progress stays up after a job that went well (Enyo's 2 s).
    property int hideProgressDelay: 2000

    readonly property bool isOpen: frame.visible
    // A job is under way: the dialog does not open again until it is done.
    readonly property bool printing: _job.active

    // "printerSelector", "printerOptions" or "printerAdder".
    property string view: "printerSelector"
    // The printers the service has found or been given: { id, name, address }.
    property var printers: []
    property var selectedPrinter: null
    property bool searching: false
    // The printer's capabilities, once printers/getCapabilities has said.
    property var capabilities: null
    property string capabilitiesError: ""

    // The options as chosen.
    property int copies: 1
    property bool duplex: false
    property bool color: true
    property string mediaSize: ""

    property bool adding: false

    // "success", "failure" (with the text shown) or "cancel".
    signal finished(string outcome, string errorText)

    // --- What the dialog shows ---------------------------------------------

    readonly property bool copiesShown: !!copiesRange && copiesRange.min > 0 && copiesRange.max > copiesRange.min
    readonly property bool duplexShown: duplexOption && !!capabilities && capabilities.canDuplex === true
    readonly property bool colorShown: colorOption && !!capabilities && capabilities.hasColor === true
    readonly property var mediaSizes: _mediaSizes(capabilities)
    readonly property bool mediaSizeShown: mediaSizeOption && mediaSizes.length > 0

    readonly property string title: view === "printerAdder" ? "Add a Printer"
                                  : view === "printerOptions" || printers.length === 0 ? "Print"
                                  : "Select a Printer"
    readonly property bool printEnabled: view === "printerOptions" ? !!capabilities
                                       : view === "printerAdder" ? addressField.text.trim() !== "" && !adding
                                       : false

    // --- Opening and closing -----------------------------------------------

    // Opens the dialog for what (a path, or a list of them); title names the
    // job. No second dialog while a job is under way: false then.
    function open(what, title) {
        if (_job.active)
            return false;
        if (what !== undefined)
            files = typeof what === "string" ? [what] : what;
        description = title || (files.length > 0 ? _name(files[0]) : "");
        _loadPrinters();
        frame.open();
        return true;
    }

    function close() {
        if (frame.visible)
            frame.close();
        _freePrinters();
    }

    // Back: the adder goes back to the printers, and the dialog closes;
    // a job's progress stays. True when Back did something here.
    function back() {
        if (view === "printerAdder") {
            cancelClicked();
            return true;
        }
        if (frame.visible) {
            close();
            return true;
        }
        if (messageBox.visible) {
            messageBox.close();
            return true;
        }
        return false;
    }

    function _name(path) {
        var p = String(path);
        return p.substring(p.lastIndexOf("/") + 1);
    }

    // --- The print service --------------------------------------------------

    readonly property string _service: "luna://com.palm.printmgr/"

    function _parse(message) {
        try {
            return JSON.parse(message.payload);
        } catch (e) {
            return { returnValue: false, errorText: "unreadable reply" };
        }
    }

    function _request(method, params, onDone, onFail) {
        if (!call) {
            if (onFail)
                onFail({ errorText: "no service" });
            return;
        }
        call(_service + method, JSON.stringify(params || {}), function(message) {
            var r = _parse(message);
            if (r.returnValue === false) {
                if (onFail)
                    onFail(r);
            } else if (onDone) {
                onDone(r);
            }
        }, function(error) {
            if (onFail)
                onFail({ errorText: String(error) });
        });
    }

    function _subscribe(method, params, onEvent, onFail) {
        if (!subscribe) {
            if (onFail)
                onFail({ errorText: "no service" });
            return null;
        }
        return subscribe(_service + method, JSON.stringify(Object.assign({ subscribe: true }, params || {})),
                         function(message) {
            var r = _parse(message);
            if (r.returnValue === false) {
                if (onFail)
                    onFail(r);
            } else {
                onEvent(r);
            }
        }, function(error) {
            if (onFail)
                onFail({ errorText: String(error) });
        });
    }

    function _cancel(c) {
        if (c && typeof c.cancel === "function")
            c.cancel();
    }

    // What the user is told for one of the print service's error codes
    // (Enyo's PrintManagerError).
    function errorText(code) {
        if (code === undefined || code === null || typeof code !== "number")
            return "Unable to process print job.";
        switch (code) {
        case -203: return "Unable to communicate with the printer. Please check the address, make sure the printer is online, and try again.";
        case -204:
        case -205: return "This printer already exists.";
        case -206: return "The IP address for the printer is not valid. Check the address, then re-enter it.";
        case -233:
        case -243: return "The printer queue is currently full. Please wait for a print job to finish before you start a new one. (error " + code + ")";
        case -238: return "This printer is currently not supported.  Please select or add another printer.";
        case -245: return "This printer was automatically discovered and is already available.";
        case -298: return "The Wi-Fi connection is unavailable. Please connect to a Wi-Fi network and try again.";
        }
        if (code <= -400 && code > -500)
            return "Unable to communicate with the printer. Please make sure the printer is online and try again.";
        return "Unable to process print job. (error " + code + ")";
    }

    // --- Printers (Enyo's PrinterSelector) --------------------------------

    property var _listCall: null
    property var _current: null

    function _loadPrinters() {
        _freePrinters();
        printers = [];
        selectedPrinter = null;
        capabilities = null;
        capabilitiesError = "";
        view = "printerSelector";
        searching = true;
        searchTimer.restart();
        _request("printers/getCurrent", {}, function(r) {
            if (!r.printerID)
                return;
            printDialog._current = printDialog._addPrinter(r);
            // The printer used last time, straight away, if none is picked yet
            if (printDialog._current && !printDialog.selectedPrinter && printDialog.view === "printerSelector")
                printDialog.selectPrinter(printDialog._current.id);
        });
        _listCall = _subscribe("printers/list", {}, function(r) {
            if (!r.printerID)
                return;
            if (r.eventType === "Add")
                printDialog._addPrinter(r);
            else if (r.eventType === "Rmv")
                printDialog._removePrinter(r.printerID);
        });
    }

    function _freePrinters() {
        searchTimer.stop();
        searching = false;
        _cancel(_listCall);
        _listCall = null;
    }

    function _find(id) {
        for (var i = 0; i < printers.length; i++) {
            if (printers[i].id === id)
                return printers[i];
        }
        return null;
    }

    function _addPrinter(r) {
        var list = printers.slice();
        var p = _find(r.printerID);
        if (p) {
            p.name = r.printerName || p.name;
            p.address = r.printerAddress || p.address;
        } else {
            p = { id: r.printerID, name: r.printerName || r.printerID, address: r.printerAddress || "" };
            list.push(p);
        }
        printers = list;
        return p;
    }

    function _removePrinter(id) {
        printers = printers.filter(function(p) { return p.id !== id; });
        if (selectedPrinter && selectedPrinter.id === id && view === "printerOptions")
            view = "printerSelector";
    }

    // Picks a printer the dialog has listed, makes it the one used next
    // time (printers/setCurrent) and shows its options.
    function selectPrinter(id) {
        var p = _find(id);
        if (!p)
            return false;
        selectedPrinter = p;
        if (p !== _current) {
            _current = p;
            _request("printers/setCurrent", { printerID: p.id });
        }
        _showOptions(p);
        return true;
    }

    // --- Options (Enyo's PrinterOptions) ----------------------------------

    function _showOptions(p) {
        view = "printerOptions";
        options.contentY = 0;
        copies = copiesShown ? copiesRange.min : 1;
        capabilitiesError = "";
        capabilities = p.capabilities || null;
        if (capabilities) {
            _applyCapabilities();
            return;
        }
        _request("printers/getCapabilities", { printerID: p.id }, function(r) {
            p.capabilities = r;
            if (printDialog.selectedPrinter === p) {
                printDialog.capabilities = r;
                printDialog._applyCapabilities();
            }
        }, function(r) {
            if (printDialog.selectedPrinter === p)
                printDialog.capabilitiesError = printDialog.errorText(r.errorCode);
        });
    }

    function _applyCapabilities() {
        duplex = false;
        color = true;
        mediaSize = _defaultMediaSize();
    }

    function _has(list, value) {
        return !!list && list.indexOf(value) >= 0;
    }

    // The paper a printer takes, by the names people know. Pictures get the
    // photo sizes, named as the region names them (Enyo's MediaSizePicker),
    // and the sheets an office printer holds besides.
    function _mediaSizes(caps) {
        if (!caps || !caps.mediaSize)
            return [];
        var metric = localPaper === "ISO_A4";
        var names = {
            "US_Letter": "Letter", "US_Legal": "Legal", "ISO_A4": "A4"
        };
        if (images) {
            names["Photo_4x6"] = metric ? "10x15cm" : "4x6";
            names["Photo_5x7"] = metric ? "13x18cm" : "5x7";
            names["Photo_5x7_MainTray"] = metric ? "13x18cm (Main Tray)" : "5x7 (Main Tray)";
            names["Photo_L"] = "L";
            names["HAGAKI"] = "Hagaki";
        }
        var sizes = [];
        for (var i = 0; i < caps.mediaSize.length; i++) {
            var key = caps.mediaSize[i];
            if (names[key])
                sizes.push({ value: key, text: names[key] });
        }
        return sizes;
    }

    function _defaultMediaSize() {
        var keys = mediaSizes.map(function(s) { return s.value; });
        if (images && keys.indexOf("Photo_4x6") >= 0)
            return "Photo_4x6";
        if (keys.indexOf(localPaper) >= 0)
            return localPaper;
        return keys.length > 0 ? keys[0] : "";
    }

    // The job's settings, from the options shown.
    function printerSettings() {
        var s = {};
        if (copiesShown)
            s.numCopies = copies;
        if (mediaSizeShown && mediaSize !== "")
            s.mediaSize = mediaSize;
        if (duplexShown)
            s.duplex = duplex ? "Book" : "None";
        if (colorShown)
            s.color = color ? "Color" : "Mono";
        if (margin) {
            if (margin.top)
                s.topInset = margin.top;
            if (margin.left)
                s.leftInset = margin.left;
            if (margin.right)
                s.rightInset = margin.right;
            if (margin.bottom)
                s.bottomInset = margin.bottom;
        }
        var insets = s.topInset !== undefined || s.leftInset !== undefined
                  || s.rightInset !== undefined || s.bottomInset !== undefined;
        var caps = capabilities || {};
        // Turned and sized to the paper, as ImagePrintJob had them. It also
        // asked for photo paper, best quality and no border every time; here
        // only where the printer has them, since the printers CUPS finds are
        // as often office lasers with plain paper.
        s.autoScale = true;
        if (images) {
            s.autoRotate = true;
            if (!insets && caps.canPrintBorderless === true)
                s.borderless = true;
            if (_has(caps.mediaType, "Photo"))
                s.mediaType = "Photo";
            if (caps.canPrintQualityHigh === true)
                s.printQuality = "Best";
        }
        if (s.mediaSize === undefined)
            s.mediaSize = localPaper;
        return s;
    }

    // --- Adding a printer (Enyo's PrinterAdder) ---------------------------

    function _showAdder() {
        addressField.text = "";
        nameField.text = "";
        adding = false;
        view = "printerAdder";
    }

    function _addTyped() {
        var address = addressField.text.trim();
        var name = nameField.text.trim();
        adding = true;
        _request("printers/add", { printerID: address, printerName: name, printerAddress: address }, function() {
            printDialog.adding = false;
            if (printDialog.view !== "printerAdder")
                return;
            printDialog.view = "printerSelector";
            printDialog._addPrinter({ printerID: address, printerName: name || address, printerAddress: address });
            printDialog.selectPrinter(address);
        }, function(r) {
            printDialog.adding = false;
            if (printDialog.view === "printerAdder")
                printDialog._showMessage(printDialog.errorText(r.errorCode));
        });
    }

    // --- The buttons --------------------------------------------------------

    function printClicked() {
        if (!printEnabled)
            return;
        if (view === "printerAdder") {
            _addTyped();
            return;
        }
        if (!selectedPrinter || files.length === 0)
            return;
        var settings = printerSettings();
        var printer = selectedPrinter.id;
        close();
        _job.start(printer, settings);
    }

    function cancelClicked() {
        if (view === "printerAdder") {
            adding = false;
            view = "printerSelector";
        } else {
            close();
        }
    }

    function _showMessage(text) {
        messageBox.text = text;
        messageBox.open();
    }

    // --- The job (Enyo's PrintJob and ImagePrintJob) ----------------------

    QtObject {
        id: _job

        property bool active: false
        property var jobID: null
        property bool canceled: false
        property bool failed: false
        property string failure: ""
        property var openCall: null
        property var statusCall: null
        // finish() has run: a subscription that answers inside its own
        // subscribe() can end the job before the call is kept
        property bool ended: false
        property int step: 0
        readonly property int steps: 3 + printDialog.files.length
        property var settings: ({})

        function start(printerID, inSettings) {
            active = true;
            ended = false;
            jobID = null;
            canceled = false;
            failed = false;
            failure = "";
            step = 0;
            settings = inSettings;
            progress.title = "Preparing to print...";
            progress.message = " ";
            progressCancel.enabled = true;
            progress.open();
            // The Print Manager, headless, which tells how the job goes
            if (printDialog.call && printDialog.printManagerId !== "") {
                printDialog.call("luna://com.palm.applicationManager/open",
                                 JSON.stringify({ id: printDialog.printManagerId,
                                                  params: { "$disableCardPreLaunch": true, runHeadless: true } }),
                                 function() {}, function() {});
            }
            keep("openCall", printDialog._subscribe("jobs/open", { printerID: printerID, description: printDialog.description,
                                                                   appName: printDialog.appName }, opened, fail));
        }

        function keep(name, c) {
            if (ended)
                printDialog._cancel(c);
            else
                _job[name] = c;
        }

        function opened(r) {
            if (jobID !== null || r.jobID === undefined)
                return;
            jobID = r.jobID;
            step++;
            if (canceled) {
                printDialog._request("jobs/cancel", { jobID: jobID }, finish, close);
                return;
            }
            printDialog._request("jobs/editPrintParams", Object.assign({ jobID: jobID }, settings), edited, fail);
        }

        function edited() {
            step++;
            if (!canceled)
                printDialog._request("jobs/getFinalParamsAndArea", { jobID: jobID }, ready, fail);
        }

        function ready() {
            step++;
            if (canceled)
                return;
            // To learn when the printer is done, or gave up
            keep("statusCall", printDialog._subscribe("jobs/getStatus", {}, status, function() {}));
            add(0);
        }

        function add(i) {
            var total = printDialog.files.length;
            if (i >= total) {
                close();
                return;
            }
            if (printDialog.images)
                progress.message = "Image " + (i + 1) + " of " + total;
            else if (total > 1)
                progress.message = "Page " + (i + 1) + " of " + total;
            printDialog._request("jobs/addFile", { jobID: jobID, pathName: String(printDialog.files[i]),
                                                   currentPage: i + 1, totalPages: total }, function() {
                _job.step++;
                if (!_job.canceled)
                    _job.add(i + 1);
            }, function(r) {
                if (!_job.failed) {
                    _job.failed = true;
                    _job.failure = printDialog.errorText(r.errorCode);
                }
                // A page that could not be added: the printer says when it is done
                if (r.errorCode !== -219 && r.errorCode !== -703)
                    _job.close();
            });
        }

        function status(r) {
            if (jobID === null || r.jobID !== jobID || r.printerState !== "DONE")
                return;
            if (r.jobStatus === "Cancelled") {
                canceled = true;
            } else if (r.jobStatus !== "Success" && !failed) {
                failed = true;
                failure = "Unable to process print job.";
            }
            close();
        }

        function fail(r) {
            if (!active)
                return;
            failed = true;
            failure = printDialog.errorText(r.errorCode);
            if (jobID !== null)
                close();
            else
                finish();
        }

        function close() {
            printDialog._request("jobs/close", { jobID: jobID }, finish, finish);
        }

        function cancel() {
            canceled = true;
            progressCancel.enabled = false;
            progress.title = "Canceling print job...";
            if (jobID !== null)
                printDialog._request("jobs/cancel", { jobID: jobID }, finish, close);
        }

        function finish() {
            if (!active || ended)
                return;
            ended = true;
            printDialog._cancel(statusCall);
            printDialog._cancel(openCall);
            statusCall = null;
            openCall = null;
            if (canceled || failed || printDialog.hideProgressDelay <= 0)
                done();
            else
                hideTimer.restart();
        }

        function done() {
            hideTimer.stop();
            progress.close();
            active = false;
            if (canceled) {
                printDialog.finished("cancel", "");
            } else if (failed) {
                printDialog._showMessage(failure);
                printDialog.finished("failure", failure);
            } else {
                printDialog.finished("success", "");
            }
        }
    }

    Timer {
        id: hideTimer
        interval: printDialog.hideProgressDelay
        onTriggered: _job.done()
    }

    Timer {
        id: searchTimer
        interval: printDialog.searchTimeout
        onTriggered: printDialog.searching = false
    }

    // --- Drawing -----------------------------------------------------------

    readonly property real _width: Math.min(Units.gu(30), width - Units.gu(2))
    readonly property real _rowHeight: Units.gu(5.4)
    readonly property int _fontSize: FontUtils.sizeToPixels("medium")
    readonly property color _labelColor: "#363636"

    // A row of the group: Enyo's Item, #eee with a rule under it.
    // The first row is rounded at the top, as the group is (Enyo's
    // enyo-first): square, it covered the group's corners.
    component GroupRow: Item {
        id: groupRow
        property color color: "#eeeeee"
        // Down to this colour, for a gradient
        property color bottomColor: color
        property bool first: false
        readonly property real _radius: first ? Units.gu(1) : 0
        width: parent ? parent.width : 0
        height: printDialog._rowHeight
        // Rounded at the top only: one taller by the radius, its foot cut off
        Item {
            anchors.fill: parent
            clip: groupRow.first
            Rectangle {
                width: parent.width
                height: parent.height + groupRow._radius
                radius: groupRow._radius
                gradient: Gradient {
                    GradientStop { position: 0; color: groupRow.color }
                    GradientStop { position: 1; color: groupRow.bottomColor }
                }
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#bebebe"
        }
    }

    // A label on the left of an option row.
    component RowLabel: Text {
        anchors.left: parent.left
        anchors.leftMargin: Units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        font.family: "Prelude"
        font.pixelSize: printDialog._fontSize
        color: printDialog._labelColor
        elide: Text.ElideRight
    }

    // A wide button inside the group, as Add a Printer and Select Another
    // Printer are.
    component GroupButton: Button {
        width: parent ? parent.width - Units.gu(2.6) : 0
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        LuneOSButton.mainColor: LuneOSButton.secondaryColor
    }

    LC.Dialog {
        id: frame
        objectName: "printDialog"
        visible: false
        title: printDialog.title
        dialogWidth: printDialog._width
        dialogHeight: fittedHeight

        onClosed: printDialog._freePrinters()

        Column {
            width: frame.contentWidth
            spacing: Units.gu(1)

            // The group the views are drawn in (Enyo's ModalDialog .group).
            BorderImage {
                id: group
                width: parent.width
                height: Units.gu(22.4)
                source: "images/dialog-group-unlabeled.png"
                border { left: 14; top: 14; right: 14; bottom: 14 }
                horizontalTileMode: BorderImage.Stretch
                verticalTileMode: BorderImage.Stretch

                Item {
                    id: inner
                    anchors.fill: parent
                    anchors.margins: 3
                    clip: true

                    // Locating Printers... / No printers are currently available.
                    Column {
                        objectName: "searchView"
                        visible: printDialog.view === "printerSelector" && printDialog.printers.length === 0
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: Units.gu(1)
                        Text {
                            objectName: "searchMessage"
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            font.family: "Prelude"
                            font.pixelSize: printDialog._fontSize
                            color: printDialog._labelColor
                            text: printDialog.searching ? "Locating Printers..." : "No printers are currently available."
                        }
                        BusyIndicator {
                            anchors.horizontalCenter: parent.horizontalCenter
                            running: printDialog.searching
                            visible: printDialog.searching
                        }
                        GroupButton {
                            objectName: "addPrinterButton"
                            text: "Add a Printer"
                            onClicked: printDialog._showAdder()
                        }
                    }

                    ListView {
                        id: printerList
                        objectName: "printerList"
                        anchors.fill: parent
                        visible: printDialog.view === "printerSelector" && printDialog.printers.length > 0
                        model: printDialog.printers
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: GroupRow {
                            id: printerRow
                            required property var modelData
                            required property int index
                            objectName: "printer_" + modelData.id
                            first: index === 0
                            color: rowArea.pressed ? "#d8d8d8" : "#eeeeee"
                            RowLabel {
                                anchors.right: parent.right
                                anchors.rightMargin: Units.gu(1)
                                text: printerRow.modelData.name
                            }
                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                onClicked: printDialog.selectPrinter(printerRow.modelData.id)
                            }
                        }
                        // The last row: Add a Printer, on the group's own ground
                        footer: Item {
                            width: printerList.width
                            height: printDialog._rowHeight
                            GroupButton {
                                objectName: "addPrinterRowButton"
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Add a Printer"
                                onClicked: printDialog._showAdder()
                            }
                        }
                    }

                    Flickable {
                        id: options
                        objectName: "printerOptions"
                        anchors.fill: parent
                        visible: printDialog.view === "printerOptions"
                        contentHeight: optionsColumn.height
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Column {
                            id: optionsColumn
                            width: options.width

                            // The printer, on Enyo's grey gradient
                            GroupRow {
                                first: true
                                color: "#ebebeb"
                                bottomColor: "#c5c5c5"
                                RowLabel {
                                    objectName: "selectedPrinterName"
                                    anchors.right: parent.right
                                    anchors.rightMargin: Units.gu(1)
                                    color: "black"
                                    text: printDialog.selectedPrinter ? printDialog.selectedPrinter.name : ""
                                }
                            }

                            GroupRow {
                                visible: printDialog.copiesShown && !!printDialog.capabilities
                                RowLabel {
                                    anchors.right: copiesPicker.left
                                    text: "Number of Copies"
                                }
                                // Enyo's IntegerPicker: a pill with the number
                                ComboBox {
                                    id: copiesPicker
                                    objectName: "copiesPicker"
                                    anchors.right: parent.right
                                    anchors.rightMargin: Units.gu(1)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Units.gu(5.5)
                                    height: Units.gu(4)
                                    model: {
                                        var list = [];
                                        if (printDialog.copiesShown) {
                                            for (var n = printDialog.copiesRange.min; n <= printDialog.copiesRange.max; n++)
                                                list.push(n);
                                        }
                                        return list;
                                    }
                                    currentIndex: printDialog.copiesShown ? printDialog.copies - printDialog.copiesRange.min : -1
                                    onActivated: function(i) { printDialog.copies = printDialog.copiesRange.min + i; }
                                    indicator: null
                                    background: BorderImage {
                                        source: copiesPicker.pressed ? "images/picker-pill-downstate.png" : "images/picker-pill.png"
                                        border { left: 10; top: 10; right: 10; bottom: 10 }
                                    }
                                    contentItem: Text {
                                        text: String(printDialog.copies)
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.family: "Prelude"
                                        font.pixelSize: printDialog._fontSize
                                        color: printDialog._labelColor
                                    }
                                }
                            }

                            GroupRow {
                                visible: printDialog.mediaSizeShown
                                RowLabel {
                                    anchors.right: sizePicker.left
                                    text: "Size"
                                }
                                ComboBox {
                                    id: sizePicker
                                    objectName: "sizePicker"
                                    anchors.right: parent.right
                                    anchors.rightMargin: Units.gu(1)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Units.gu(12)
                                    model: printDialog.mediaSizes
                                    textRole: "text"
                                    valueRole: "value"
                                    currentIndex: {
                                        for (var i = 0; i < printDialog.mediaSizes.length; i++) {
                                            if (printDialog.mediaSizes[i].value === printDialog.mediaSize)
                                                return i;
                                        }
                                        return -1;
                                    }
                                    onActivated: function(i) { printDialog.mediaSize = printDialog.mediaSizes[i].value; }
                                }
                            }

                            GroupRow {
                                visible: printDialog.duplexShown
                                RowLabel {
                                    anchors.right: duplexSwitch.left
                                    text: "2-Sided Printing"
                                }
                                Switch {
                                    id: duplexSwitch
                                    objectName: "duplexSwitch"
                                    anchors.right: parent.right
                                    anchors.rightMargin: Units.gu(1)
                                    anchors.verticalCenter: parent.verticalCenter
                                    checked: printDialog.duplex
                                    onToggled: printDialog.duplex = checked
                                }
                            }

                            GroupRow {
                                visible: printDialog.colorShown
                                RowLabel {
                                    anchors.right: colorSwitch.left
                                    text: "Color Printing"
                                }
                                Switch {
                                    id: colorSwitch
                                    objectName: "colorSwitch"
                                    anchors.right: parent.right
                                    anchors.rightMargin: Units.gu(1)
                                    anchors.verticalCenter: parent.verticalCenter
                                    checked: printDialog.color
                                    onToggled: printDialog.color = checked
                                }
                            }

                            // Asking the printer what it can do, or why it would not say
                            GroupRow {
                                objectName: "gettingCapabilities"
                                visible: !printDialog.capabilities
                                height: Units.gu(9)
                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - Units.gu(2)
                                    spacing: Units.gu(0.5)
                                    Text {
                                        objectName: "capabilitiesMessage"
                                        width: parent.width
                                        visible: text !== ""
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.Wrap
                                        font.family: "Prelude"
                                        font.pixelSize: printDialog._fontSize
                                        color: printDialog._labelColor
                                        text: printDialog.capabilitiesError
                                    }
                                    BusyIndicator {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        running: visible
                                        visible: printDialog.capabilitiesError === ""
                                    }
                                }
                            }

                            Item {
                                width: parent.width
                                height: printDialog._rowHeight
                                GroupButton {
                                    objectName: "selectAnotherPrinterButton"
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Select Another Printer"
                                    onClicked: printDialog.view = "printerSelector"
                                }
                            }
                        }
                    }

                    // The printer's address and a name for it
                    Column {
                        objectName: "printerAdder"
                        visible: printDialog.view === "printerAdder"
                        anchors.fill: parent
                        anchors.margins: Units.gu(1)
                        spacing: Units.gu(1)
                        TextField {
                            id: addressField
                            objectName: "printerAddressField"
                            width: parent.width
                            placeholderText: "Enter Printer IP address"
                            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferNumbers
                            onAccepted: printDialog.printClicked()
                        }
                        TextField {
                            id: nameField
                            objectName: "printerNameField"
                            width: parent.width
                            placeholderText: "Name Printer"
                            onAccepted: printDialog.printClicked()
                        }
                        BusyIndicator {
                            anchors.horizontalCenter: parent.horizontalCenter
                            running: printDialog.adding
                            visible: printDialog.adding
                        }
                    }
                }
            }

            // Cancel, and Print (Done when adding) in Enyo's dark button
            Row {
                width: parent.width
                spacing: Units.gu(1)
                Button {
                    objectName: "printDialogCancel"
                    width: (parent.width - parent.spacing) / 2
                    text: "Cancel"
                    LuneOSButton.mainColor: LuneOSButton.secondaryColor
                    onClicked: printDialog.cancelClicked()
                }
                Button {
                    objectName: "printDialogPrint"
                    width: (parent.width - parent.spacing) / 2
                    // Green, as webOS's affirmative buttons
                    LuneOSButton.mainColor: LuneOSButton.affirmativeColor
                    text: printDialog.view === "printerAdder" ? "Done" : "Print"
                    enabled: printDialog.printEnabled
                    onClicked: printDialog.printClicked()
                }
            }
        }
    }

    // "Preparing to print...", how far the job got, and Cancel (Enyo's
    // ProgressPopup)
    LC.Dialog {
        id: progress
        objectName: "printProgress"
        visible: false
        dialogWidth: printDialog._width
        dialogHeight: fittedHeight
        messageAlignment: Text.AlignHCenter

        Column {
            width: progress.contentWidth
            spacing: Units.gu(1)
            ProgressBar {
                objectName: "printProgressBar"
                width: parent.width
                from: 0
                to: _job.steps
                value: _job.step
            }
            Button {
                id: progressCancel
                objectName: "printProgressCancel"
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width / 2
                text: "Cancel"
                LuneOSButton.mainColor: LuneOSButton.secondaryColor
                onClicked: _job.cancel()
            }
        }
    }

    // Why a job did not print, with Close (Enyo's MessageBox)
    LC.Dialog {
        id: messageBox
        objectName: "printMessage"
        visible: false
        dialogWidth: printDialog._width
        dialogHeight: fittedHeight

        property string text: ""

        Column {
            width: messageBox.contentWidth
            spacing: Units.gu(2)
            Row {
                width: parent.width
                spacing: Units.gu(2)
                Image {
                    source: "images/print-warning.png"
                    width: Units.gu(4.8)
                    height: Units.gu(4.8)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    objectName: "printMessageText"
                    width: parent.width - Units.gu(6.8)
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.Wrap
                    font.family: "Prelude"
                    font.pixelSize: printDialog._fontSize
                    color: "black"
                    text: messageBox.text
                }
            }
            Button {
                objectName: "printMessageClose"
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width / 2
                text: "Close"
                LuneOSButton.mainColor: LuneOSButton.secondaryColor
                onClicked: messageBox.close()
            }
        }
    }
}
