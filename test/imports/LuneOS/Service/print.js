/*
 * Mock data for org.webosports.service.print (luneos-print-adapter's
 * "Settings app" surface, alongside the legacy com.palm.printmgr/
 * com.webos.service.print webOS API it doesn't replicate here). Field
 * names, the state vocabulary and the method names all come straight from
 * print_service.c's ports_* handlers - see the "org.webosports.service.print
 * - the Settings app's Print Manager" section there.
 *
 * Like wan.js/vpn.js, this is a .pragma library so LunaService.qml
 * instances share one printer/job list.
 */
.pragma library

var printers = [
    { "printerId": "hp-laserjet-mdns", "name": "HP LaserJet M404 (living room)",
      "uri": "ipp://hplaserjet.local:631/ipp/print", "location": "Living room",
      "makeAndModel": "HP LaserJet M404dn", "state": "idle", "discovered": true },
    { "printerId": "epson-et-mdns", "name": "Epson ET-2850",
      "uri": "ipp://epson-et2850.local:631/ipp/print", "location": "",
      "makeAndModel": "Epson ET-2850 Series", "state": "processing", "discovered": true },
    { "printerId": "office_mfp", "name": "Office MFP",
      "uri": "ipp://192.168.1.50:631/ipp/print", "location": "",
      "makeAndModel": "", "state": "idle", "discovered": false }
];

var defaultPrinterId = "hp-laserjet-mdns";

// pages/completedPages are always 0 on the real ports_jobs_payload() too -
// cups_job_t carries no impression counts, so the page falls back to a
// plain "Printing" rather than "3 of 8" for a real job. Kept non-zero here
// only to show that the UI *can* render progress, for a mock job that
// exists purely to be looked at.
var jobs = [
    { "jobId": 101, "title": "Quarterly Report.pdf", "printerId": "epson-et-mdns",
      "printerName": "Epson ET-2850", "state": "processing", "pages": 8, "completedPages": 3 },
    { "jobId": 102, "title": "Boarding Pass.pdf", "printerId": "hp-laserjet-mdns",
      "printerName": "HP LaserJet M404 (living room)", "state": "pending", "pages": 1, "completedPages": 0 },
    { "jobId": 100, "title": "Old Receipt.pdf", "printerId": "hp-laserjet-mdns",
      "printerName": "HP LaserJet M404 (living room)", "state": "completed", "pages": 1, "completedPages": 1 }
];

var printerSubscribers = [];
var jobSubscribers = [];

function printersPayload() {
    return { "returnValue": true, "printers": printers, "defaultPrinterId": defaultPrinterId };
}

function jobsPayload() {
    return { "returnValue": true, "jobs": jobs };
}

function postPrinters() {
    var payload = { "payload": JSON.stringify(printersPayload()) };
    for (var i = 0; i < printerSubscribers.length; i++)
        printerSubscribers[i](payload);
}

function postJobs() {
    var payload = { "payload": JSON.stringify(jobsPayload()) };
    for (var i = 0; i < jobSubscribers.length; i++)
        jobSubscribers[i](payload);
}

function _findPrinterIndex(printerId) {
    for (var i = 0; i < printers.length; i++) {
        if (printers[i].printerId === printerId)
            return i;
    }
    return -1;
}

// Mirrors ports_add_printer()'s CUPS-queue-name folding, so a mock id looks
// like a real one instead of the raw display name.
function _queueName(name) {
    var folded = name.replace(/[^A-Za-z0-9_.-]/g, "_");
    return folded !== "" ? folded : "printer";
}

function addPrinter(name, uri) {
    var printerId = _queueName(name);
    if (_findPrinterIndex(printerId) >= 0)
        return { "returnValue": false, "errorCode": -204, "errorText": "A printer with that id already exists." };

    printers.push({ "printerId": printerId, "name": name, "uri": uri,
                    "location": "", "makeAndModel": "", "state": "idle",
                    "discovered": false });
    postPrinters();
    return { "returnValue": true, "printerId": printerId };
}

function removePrinter(printerId) {
    var index = _findPrinterIndex(printerId);
    if (index < 0)
        return { "returnValue": false, "errorCode": -202, "errorText": "Unknown printer." };
    if (printers[index].discovered)
        return { "returnValue": false, "errorCode": -202,
                 "errorText": "This printer was auto-discovered and cannot be removed." };

    printers.splice(index, 1);
    if (defaultPrinterId === printerId)
        defaultPrinterId = printers.length > 0 ? printers[0].printerId : "";
    postPrinters();
    return { "returnValue": true };
}

function setDefaultPrinter(printerId) {
    if (_findPrinterIndex(printerId) < 0)
        return { "returnValue": false, "errorCode": -503, "errorText": "Unknown printer." };
    defaultPrinterId = printerId;
    postPrinters();
    return { "returnValue": true };
}

function cancelJob(jobId) {
    for (var i = 0; i < jobs.length; i++) {
        if (jobs[i].jobId === jobId) {
            jobs[i].state = "canceled";
            postJobs();
            return { "returnValue": true };
        }
    }
    return { "returnValue": false, "errorCode": -709, "errorText": "Unknown job." };
}

function cancelAllJobs() {
    for (var i = 0; i < jobs.length; i++) {
        if (jobs[i].state !== "completed" && jobs[i].state !== "canceled" &&
            jobs[i].state !== "aborted")
            jobs[i].state = "canceled";
    }
    postJobs();
    return { "returnValue": true };
}
