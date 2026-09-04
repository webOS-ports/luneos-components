/*
 * Mock data for org.webosports.service.certmgr (certmgrd) - a real,
 * already-built LuneOS service, not a placeholder: field names and the
 * method table (listAll/install/remove, no subscribe support on listAll)
 * come straight from certmgr_service.c's own LSMethod table and its
 * ports_certs_payload-equivalent jobject_put() calls.
 *
 * Like vpn.js/print.js, this is a .pragma library so LunaService.qml
 * instances share one certificate list.
 */
.pragma library

var certificates = [
    { "serial": 1, "start": "Jan  1 00:00:00 2024 GMT", "expiration": "Jan  1 00:00:00 2034 GMT",
      "issuer": "LuneOS Root CA", "issuerOrganization": "LuneOS", "issuerOrganizationUnit": "",
      "subject": "LuneOS Root CA", "subjectSurname": "",
      "subjectOrganization": "LuneOS", "subjectOrganizationUnit": "" },
    { "serial": 2, "start": "Jun 15 00:00:00 2025 GMT", "expiration": "Jun 15 00:00:00 2026 GMT",
      "issuer": "R10", "issuerOrganization": "Let's Encrypt", "issuerOrganizationUnit": "",
      "subject": "vpn.work.example.com", "subjectSurname": "",
      "subjectOrganization": "", "subjectOrganizationUnit": "" }
];

var _nextSerial = 3;

function listAllPayload() {
    return { "returnValue": true, "certificates": certificates };
}

function _findIndex(serial) {
    for (var i = 0; i < certificates.length; i++) {
        if (certificates[i].serial === serial)
            return i;
    }
    return -1;
}

// No real file to parse here - the mock just makes up plausible-looking
// fields from the file name, the way the real service would after
// actually reading the certificate/PKCS#12 bundle at path.
function install(path, passphrase) {
    var fileName = (path || "certificate").split("/").pop();
    var serial = _nextSerial++;

    certificates.push({
        "serial": serial,
        "start": "Jan  1 00:00:00 2026 GMT",
        "expiration": "Jan  1 00:00:00 2036 GMT",
        "issuer": fileName, "issuerOrganization": "", "issuerOrganizationUnit": "",
        "subject": fileName, "subjectSurname": "",
        "subjectOrganization": "", "subjectOrganizationUnit": ""
    });
    return { "returnValue": true };
}

function remove(serial) {
    var index = _findIndex(serial);
    if (index < 0)
        return { "returnValue": false, "errorText": "Could not remove certificate" };

    certificates.splice(index, 1);
    return { "returnValue": true };
}
