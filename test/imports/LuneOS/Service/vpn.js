/*
 * Mock data for com.webos.service.vpn (luneos-vpn-adapter), the LS2 service
 * VPNPage.qml/VpnProfilePopup.qml/VpnPromptPopup.qml drive. See
 * luneos-vpn-api.md in the LuneOS VPN project for the real contract this
 * mirrors - method names, error codes and the vpnFormFields schema are taken
 * straight from there so a page written against this mock needs no changes
 * against the real service.
 *
 * Like wan.js, this is a .pragma library so LunaService.qml instances share
 * one profile list: VPNPage's getProfileList subscription and a later
 * connect/addProfile call have to see the same state, the way they would
 * through the real bus.
 */
.pragma library

var vpnAgents = [
    { "vpnAgentGuid": "com.webos.vpn.wireguard", "vpnAgentLabel": "WireGuard",
      "vpnAgentTechnology": ["WireGuard"], "connmanType": "wireguard",
      "supportsImport": ["wg-conf"] },
    { "vpnAgentGuid": "com.webos.vpn.openvpn", "vpnAgentLabel": "OpenVPN",
      "vpnAgentTechnology": ["ssl"], "connmanType": "openvpn",
      "supportsImport": ["ovpn"] },
    { "vpnAgentGuid": "com.webos.vpn.openconnect", "vpnAgentLabel": "OpenConnect (AnyConnect)",
      "vpnAgentTechnology": ["ssl"], "connmanType": "openconnect" },
    { "vpnAgentGuid": "com.webos.vpn.vpnc", "vpnAgentLabel": "Cisco IPsec",
      "vpnAgentTechnology": ["IPSec"], "connmanType": "vpnc" },
    { "vpnAgentGuid": "com.webos.vpn.l2tp", "vpnAgentLabel": "L2TP/IPsec",
      "vpnAgentTechnology": ["L2TP"], "connmanType": "l2tp" },
    { "vpnAgentGuid": "com.webos.vpn.pptp", "vpnAgentLabel": "PPTP",
      "vpnAgentTechnology": ["PPTP"], "connmanType": "pptp", "deprecated": true }
];

// Blank vpnFormFields per provider, as getAgentFormFields would answer -
// field ids/connmanProperty values match files/formfields/*.json in
// luneos-vpn-adapter exactly, so a form built from this mock looks like the
// real one.
var blankFormFields = {
    "com.webos.vpn.wireguard": [
        { "id": "wgPrivateKey", "type": "passwordfield", "label": "Private key",
          "connmanProperty": "WireGuard.PrivateKey", "required": true },
        { "id": "wgPublicKey", "type": "textfield", "label": "Peer public key",
          "connmanProperty": "WireGuard.PublicKey", "required": true },
        { "id": "wgPresharedKey", "type": "passwordfield", "label": "Preshared key",
          "connmanProperty": "WireGuard.PresharedKey" },
        { "id": "wgAddress", "type": "textfield", "label": "Address",
          "hint": "10.2.0.2/24", "connmanProperty": "WireGuard.Address", "required": true },
        { "id": "wgDns", "type": "textfield", "label": "DNS servers",
          "hint": "comma separated", "connmanProperty": "WireGuard.DNS" },
        { "id": "wgAllowedIPs", "type": "textfield", "label": "Allowed IPs",
          "value": "0.0.0.0/0, ::/0", "connmanProperty": "WireGuard.AllowedIPs" },
        { "id": "wgEndpointPort", "type": "textfield", "label": "Endpoint port",
          "value": "51820", "inputType": "number", "connmanProperty": "WireGuard.EndpointPort" },
        { "id": "wgListenPort", "type": "textfield", "label": "Local listen port",
          "inputType": "number", "connmanProperty": "WireGuard.ListenPort" },
        { "id": "wgKeepalive", "type": "textfield", "label": "Persistent keepalive (s)",
          "inputType": "number", "connmanProperty": "WireGuard.PersistentKeepalive" }
    ],
    "com.webos.vpn.openvpn": [
        // Username/password are runtimeCredentialFields in the real
        // openvpn.json, not stored here - requested at connect time via
        // net.connman.vpn.Agent.RequestInput, same as VpnPromptPopup.
        { "id": "ovpnConfigFile", "type": "textfield", "label": "Config file",
          "hint": "use Import to set this", "editable": false,
          "connmanProperty": "OpenVPN.ConfigFile" },
        { "id": "ovpnCaCert", "type": "textfield", "label": "CA certificate",
          "connmanProperty": "OpenVPN.CACert" },
        { "id": "ovpnCert", "type": "textfield", "label": "Client certificate",
          "connmanProperty": "OpenVPN.Cert" },
        { "id": "ovpnKey", "type": "textfield", "label": "Client key",
          "connmanProperty": "OpenVPN.Key" },
        { "id": "ovpnMtu", "type": "textfield", "label": "MTU", "inputType": "number",
          "connmanProperty": "OpenVPN.MTU" }
    ],
    "com.webos.vpn.openconnect": [
        { "id": "ocAuthType", "type": "listselector", "label": "Authentication",
          "value": "cookie", "connmanProperty": "OpenConnect.AuthType",
          "options": [ { "label": "Cookie", "value": "cookie" },
                       { "label": "Username / password then cookie", "value": "cookie_with_userpass" },
                       { "label": "Username / password", "value": "userpass" },
                       { "label": "Certificate", "value": "publickey" },
                       { "label": "PKCS#12", "value": "pkcs" } ] },
        { "id": "ocUsergroup", "type": "textfield", "label": "Login group",
          "connmanProperty": "OpenConnect.Usergroup" },
        { "id": "ocCaCert", "type": "textfield", "label": "CA certificate",
          "connmanProperty": "OpenConnect.CACert" },
        { "id": "ocAllowSelfSigned", "type": "checkbox", "label": "Allow self-signed server certificate",
          "trueValue": "true", "falseValue": "false",
          "connmanProperty": "OpenConnect.AllowSelfSignedCert" },
        { "id": "ocNoDtls", "type": "checkbox", "label": "Disable DTLS / ESP",
          "trueValue": "true", "falseValue": "false",
          "connmanProperty": "OpenConnect.NoDTLS" }
    ],
    "com.webos.vpn.vpnc": [
        { "id": "vpnUserId", "type": "textfield", "label": "User name",
          "connmanProperty": "VPNC.Xauth.Username" },
        { "id": "vpnPassword", "type": "passwordfield", "label": "Password",
          "connmanProperty": "VPNC.Xauth.Password" },
        { "id": "vpnGroupId", "type": "textfield", "label": "Group name",
          "connmanProperty": "VPNC.IPSec.ID", "required": true },
        { "id": "vpnGroupSecret", "type": "passwordfield", "label": "Group password",
          "connmanProperty": "VPNC.IPSec.Secret" },
        { "id": "vpnEncryptionMethod", "type": "listselector", "label": "Encryption method",
          "value": "secure",
          "connmanPropertyMap": { "secure":       { "VPNC.SingleDES": "", "VPNC.NoEncryption": "" },
                                  "singledes":    { "VPNC.SingleDES": "yes", "VPNC.NoEncryption": "" },
                                  "noencryption": { "VPNC.SingleDES": "", "VPNC.NoEncryption": "yes" } },
          "options": [ { "label": "Secure", "value": "secure" },
                       { "label": "Single DES", "value": "singledes", "deprecated": true },
                       { "label": "No encryption", "value": "noencryption", "deprecated": true } ] },
        { "id": "vpnNatTraversal", "type": "listselector", "label": "NAT traversal",
          "value": "natt", "connmanProperty": "VPNC.NATTMode",
          "options": [ { "label": "NAT-T (auto-detect)", "value": "natt" },
                       { "label": "Cisco-UDP", "value": "cisco-udp" },
                       { "label": "NAT-T (always)", "value": "force-natt" },
                       { "label": "Disabled", "value": "none" } ] }
    ],
    "com.webos.vpn.l2tp": [
        { "id": "l2tpUser", "type": "textfield", "label": "User name",
          "connmanProperty": "L2TP.User" },
        { "id": "l2tpPassword", "type": "passwordfield", "label": "Password",
          "connmanProperty": "L2TP.Password" },
        { "id": "l2tpSecret", "type": "passwordfield", "label": "IPsec pre-shared key",
          "connmanProperty": "L2TP.IPsec.PSK" }
    ],
    "com.webos.vpn.pptp": [
        { "id": "pptpDeprecationWarning", "type": "status", "statusType": "error",
          "value": "PPTP encryption is broken and can be decrypted by an attacker. Use WireGuard or OpenVPN where possible." },
        { "id": "pptpUser", "type": "textfield", "label": "User name",
          "connmanProperty": "PPTP.User" },
        { "id": "pptpPassword", "type": "passwordfield", "label": "Password",
          "connmanProperty": "PPTP.Password" },
        { "id": "pppdReqMppe128", "type": "checkbox", "label": "Require MPPE 128-bit",
          "value": "true", "trueValue": "true", "falseValue": "false",
          "connmanProperty": "PPPD.RequirMPPE128" }
    ]
};

function _cloneFields(fields) {
    var copy = [];
    for (var i = 0; i < fields.length; i++) {
        var field = {};
        for (var key in fields[i])
            field[key] = fields[i][key];
        copy.push(field);
    }
    return copy;
}

function agentFormFields(vpnAgentGuid) {
    return _cloneFields(blankFormFields[vpnAgentGuid] || []);
}

function agentLabel(vpnAgentGuid) {
    for (var i = 0; i < vpnAgents.length; i++) {
        if (vpnAgents[i].vpnAgentGuid === vpnAgentGuid)
            return vpnAgents[i].vpnAgentLabel;
    }
    return vpnAgentGuid;
}

// Three profiles across three providers and states, plus one Immutable
// (config-provisioned) entry, so the gallery shows every row variant:
// connected, disconnected, and the no-edit/no-delete case.
var profiles = [
    {
        "vpnProfileName": "Home WireGuard",
        "vpnAgentGuid": "com.webos.vpn.wireguard",
        "vpnHost": "vpn.home.example.com",
        "vpnDomain": "",
        "vpnProfileConnectState": "connected",
        "immutable": false,
        "splitRouting": false,
        "vpnFormFields": (function() {
            var fields = _cloneFields(blankFormFields["com.webos.vpn.wireguard"]);
            for (var i = 0; i < fields.length; i++) {
                if (fields[i].id === "wgPrivateKey") { fields[i].value = "gI6EdUSY..."; fields[i].hasStoredValue = true; }
                if (fields[i].id === "wgPublicKey") fields[i].value = "HIgo9xNz...";
                if (fields[i].id === "wgAddress") fields[i].value = "10.2.0.2/24";
            }
            return fields;
        })()
    },
    {
        "vpnProfileName": "Work OpenVPN",
        "vpnAgentGuid": "com.webos.vpn.openvpn",
        "vpnHost": "vpn.work.example.com",
        "vpnDomain": "corp.example.com",
        "vpnProfileConnectState": "disconnected",
        "immutable": false,
        "splitRouting": false,
        "vpnFormFields": (function() {
            var fields = _cloneFields(blankFormFields["com.webos.vpn.openvpn"]);
            for (var i = 0; i < fields.length; i++) {
                if (fields[i].id === "ovpnConfigFile") fields[i].value = "config.ovpn";
                if (fields[i].id === "ovpnCaCert") fields[i].value = "/var/lib/connman-vpn/certs/Work OpenVPN/ca.pem";
            }
            return fields;
        })()
    },
    {
        "vpnProfileName": "Office Cisco",
        "vpnAgentGuid": "com.webos.vpn.vpnc",
        "vpnHost": "vpn.office.example.com",
        "vpnDomain": "",
        "vpnProfileConnectState": "disconnected",
        "immutable": false,
        "splitRouting": false,
        "vpnFormFields": _cloneFields(blankFormFields["com.webos.vpn.vpnc"])
    },
    {
        "vpnProfileName": "Provisioned Site-to-Site",
        "vpnAgentGuid": "com.webos.vpn.l2tp",
        "vpnHost": "10.0.0.1",
        "vpnDomain": "",
        "vpnProfileConnectState": "disconnected",
        "immutable": true,
        "splitRouting": true,
        "vpnFormFields": _cloneFields(blankFormFields["com.webos.vpn.l2tp"])
    }
];

var profileListSubscribers = [];
var statusSubscribers = [];

function _profileSummary(profile) {
    return {
        "vpnProfileName": profile.vpnProfileName,
        "vpnAgentGuid": profile.vpnAgentGuid,
        "vpnHost": profile.vpnHost,
        "vpnProfileConnectState": profile.vpnProfileConnectState,
        "immutable": profile.immutable,
        "splitRouting": profile.splitRouting
    };
}

function profileListPayload() {
    var list = [];
    for (var i = 0; i < profiles.length; i++)
        list.push(_profileSummary(profiles[i]));
    return { "returnValue": true, "vpnProfiles": list };
}

function statusPayload() {
    var active = [];
    for (var i = 0; i < profiles.length; i++) {
        if (profiles[i].vpnProfileConnectState !== "disconnected") {
            active.push({
                "vpnProfileName": profiles[i].vpnProfileName,
                "vpnAgentGuid": profiles[i].vpnAgentGuid,
                "vpnProfileConnectState": profiles[i].vpnProfileConnectState
            });
        }
    }
    return { "returnValue": true, "subscribed": true, "connmanVpnAvailable": true,
             "activeProfiles": active };
}

function postProfileList() {
    var payload = { "payload": JSON.stringify(profileListPayload()) };
    for (var i = 0; i < profileListSubscribers.length; i++)
        profileListSubscribers[i](payload);
}

function postStatus(extra) {
    var body = extra || statusPayload();
    var payload = { "payload": JSON.stringify(body) };
    for (var i = 0; i < statusSubscribers.length; i++)
        statusSubscribers[i](payload);
}

function _findIndex(name) {
    for (var i = 0; i < profiles.length; i++) {
        if (profiles[i].vpnProfileName === name)
            return i;
    }
    return -1;
}

function findProfile(name) {
    var index = _findIndex(name);
    return index >= 0 ? profiles[index] : null;
}

// Immediate half of connect/disconnect: flips to the busy state and posts
// right away, so a tapped row shows its BusyIndicator without waiting on
// the settle timer LunaService.qml drives for the second half.
function beginTransition(name, busyState) {
    var profile = findProfile(name);
    if (!profile || profile.vpnProfileConnectState === busyState)
        return false;
    profile.vpnProfileConnectState = busyState;
    postProfileList();
    postStatus();
    return true;
}

function settleTransition(name, finalState) {
    var profile = findProfile(name);
    if (!profile)
        return;
    profile.vpnProfileConnectState = finalState;
    postProfileList();
    postStatus();
}

function addProfile(name, vpnAgentGuid, host, domain, vpnFormFields) {
    if (_findIndex(name) >= 0)
        return { "returnValue": false, "errorCode": -4, "errorText": "A profile with that name already exists." };

    profiles.push({
        "vpnProfileName": name,
        "vpnAgentGuid": vpnAgentGuid,
        "vpnHost": host,
        "vpnDomain": domain,
        "vpnProfileConnectState": "disconnected",
        "immutable": false,
        "splitRouting": false,
        "vpnFormFields": vpnFormFields || []
    });
    postProfileList();
    return { "returnValue": true };
}

function updateProfile(name, host, domain, vpnFormFields) {
    var profile = findProfile(name);
    if (!profile)
        return { "returnValue": false, "errorCode": -3, "errorText": "No such profile." };
    if (profile.immutable)
        return { "returnValue": false, "errorCode": -10, "errorText": "This profile is provisioned by a config file." };

    profile.vpnHost = host;
    profile.vpnDomain = domain;
    profile.vpnFormFields = vpnFormFields || profile.vpnFormFields;
    postProfileList();
    return { "returnValue": true };
}

function deleteProfile(name) {
    var index = _findIndex(name);
    if (index < 0)
        return { "returnValue": false, "errorCode": -3, "errorText": "No such profile." };
    if (profiles[index].immutable)
        return { "returnValue": false, "errorCode": -10, "errorText": "This profile is provisioned by a config file." };

    profiles.splice(index, 1);
    postProfileList();
    return { "returnValue": true };
}

// No real file to parse here - the mock just infers a plausible agent from
// the format, the way the real importProfile would after actually reading
// the file, so the imported row shows up looking right.
var _formatAgent = {
    "wg-conf": "com.webos.vpn.wireguard",
    "ovpn": "com.webos.vpn.openvpn",
    "connman-config": "com.webos.vpn.openvpn"
};

function importProfile(name, format, filePath) {
    if (_findIndex(name) >= 0)
        return { "returnValue": false, "errorCode": -4, "errorText": "A profile with that name already exists." };

    var vpnAgentGuid = _formatAgent[format] || "com.webos.vpn.openvpn";
    profiles.push({
        "vpnProfileName": name,
        "vpnAgentGuid": vpnAgentGuid,
        "vpnHost": "imported.example.com",
        "vpnDomain": "",
        "vpnProfileConnectState": "disconnected",
        // connman-config profiles are provisioned by the config file itself
        // and cannot be edited or deleted through the API - see
        // luneos-vpn-api.md's importProfile.
        "immutable": format === "connman-config",
        "splitRouting": false,
        "vpnFormFields": agentFormFields(vpnAgentGuid)
    });
    postProfileList();
    return { "returnValue": true, "vpnProfileName": name, "vpnAgentGuid": vpnAgentGuid };
}

function importCertificate(name, role, filePath) {
    var fileName = filePath.split("/").pop() || (role + ".pem");
    return { "returnValue": true,
             "path": "/var/lib/connman-vpn/certs/" + name + "/" + fileName };
}
