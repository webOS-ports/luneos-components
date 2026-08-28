/*
 * Copyright (C) 2026 WebOS Ports
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

// Desktop mock of LuneOS.Telephony's LibPhoneNumber.
//
// The real wrapper loads the phonenumberlib loadable framework from
// /usr/palm/frameworks, which does not exist on a development machine -- the
// import throws and takes the whole app down with it. This stands in with
// grouping rules good enough to see that formatting is wired up, and the same
// reversed normalisation the real one produces so contact matching behaves.

.pragma library

var PhoneNumberType = {
    "type_mobile": "MOBILE",
    "type_home": "HOME",
    "type_home2": "HOME2",
    "type_work": "WORK",
    "type_work2": "WORK2",
    "type_main": "MAIN",
    "type_personal_fax": "PERSONAL_FAX",
    "type_work_fax": "WORK_FAX",
    "type_pager": "PAGER",
    "type_personal": "PERSONAL",
    "type_sim": "SIM",
    "type_assistant": "ASSISTANT",
    "type_car": "CAR",
    "type_radio": "RADIO",
    "type_company": "COMPANY",
    "type_other": "OTHER"
};

// Just enough country codes to make the mock contacts read correctly.
var _countryCodes = { "31": "NL", "32": "BE", "33": "FR", "49": "DE", "44": "GB",
                      "1": "US", "34": "ES", "39": "IT", "351": "PT", "420": "CZ", "46": "SE" };

var _geolocations = { "31": { location: "Netherlands", country: { sn: "NL" } },
                      "32": { location: "Belgium", country: { sn: "BE" } },
                      "49": { location: "Germany", country: { sn: "DE" } },
                      "44": { location: "United Kingdom", country: { sn: "GB" } },
                      "1":  { location: "North America", country: { sn: "US" } } };

function getPhoneNumberTypeStr(phoneNumberType) {
    return PhoneNumberType.hasOwnProperty(phoneNumberType) ? PhoneNumberType[phoneNumberType]
                                                           : "OTHER";
}

function _countryCodeOf(digits) {
    for (var length = 3; length >= 1; --length) {
        var prefix = digits.substr(0, length);
        if (_countryCodes[prefix]) return prefix;
    }
    return "";
}

/// Groups a number so it is readable: "+31 6 2148 9831", "06 2148 9831".
function formatPhoneNumberForDisplay(phoneNumber, countryCode) {
    var raw = String(phoneNumber === undefined || phoneNumber === null ? "" : phoneNumber).trim();
    if (raw.length === 0) return "";

    // Anything that is not a plain number is shown exactly as it is.
    if (!/^\+?[0-9 ().-]+$/.test(raw)) return raw;

    var digits = raw.replace(/[^0-9+]/g, '');
    var international = digits.charAt(0) === '+';
    var bare = international ? digits.slice(1) : digits;

    var prefix = "";
    if (international) {
        var code = _countryCodeOf(bare);
        prefix = "+" + code + " ";
        bare = bare.slice(code.length);
    }

    if (bare.length <= 4)
        return prefix + bare;

    // Mobile-style grouping: a leading digit, then pairs of four.
    var groups = [];
    var rest = bare;
    if (rest.length % 4 !== 0) {
        var lead = rest.length % 4;
        groups.push(rest.substr(0, lead));
        rest = rest.slice(lead);
    }
    while (rest.length > 0) {
        groups.push(rest.substr(0, 4));
        rest = rest.slice(4);
    }

    return prefix + groups.join(" ");
}

/**
 * The reversed form the real wrapper produces, so that the prefix comparisons
 * the contacts model does against stored normalizedValue behave the same way.
 */
function normalizePhoneNumber(phoneNumber, countryCode) {
    var digits = String(phoneNumber || "").replace(/[^0-9+]/g, '');
    var international = digits.charAt(0) === '+';
    var bare = international ? digits.slice(1) : digits;

    var code = international ? _countryCodeOf(bare) : "";
    var national = bare.slice(code.length);
    var leading = (!international && national.charAt(0) === '0') ? "0" : "";
    if (leading.length > 0) national = national.slice(1);

    var normalized = "+-" + code + "-" + leading + "-" + national + "-";
    return normalized.split("").reverse().join("");
}

function getNumberGeolocation(phoneNumber, countryCode, cb) {
    if (typeof cb !== 'function') return;

    var digits = String(phoneNumber || "").replace(/[^0-9+]/g, '');
    if (digits.charAt(0) !== '+') {
        cb({ parsed: true, location: "Local", country: { sn: countryCode || "" } });
        return;
    }

    var code = _countryCodeOf(digits.slice(1));
    var known = _geolocations[code];
    cb(known ? { parsed: true, location: known.location, country: known.country }
             : { parsed: true, location: "Unknown", country: { sn: "" } });
}
