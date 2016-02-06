.pragma library

// Only some simple wrappers around PhoneNumber.js to easily use it from QML

/**** version using google-phonenumber JS library ****/
/*
var modules = modules || {};
Qt.include("libphonenumber.js");

var PhoneNumberFormat = i18n.phonenumbers.PhoneNumberFormat;
var PhoneNumberUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();

function normalizePhoneNumber(phoneNumber, countryCode)
{
    var phoneNumberObj = PhoneNumberUtil.parse(phoneNumber, countryCode);

    // try to be compatible with Enyo g11n

    // reverse of "+-countrycode--national_number-extension"

    var normalizedNumber = "+-"+phoneNumberObj.getCountryCodeOrDefault() + "--" + phoneNumberObj.getNationalNumberOrDefault() + "-" + phoneNumberObj.getExtensionOrDefault();
    var reversedNormalizedNumber = normalizedNumber.split("").reverse().join("");

    console.log("normalizePhoneNumber("+phoneNumber+")="+reversedNormalizedNumber);
    return reversedNormalizedNumber;
}
*/

/**** version using luneos' telephony-lib ******/
var phoneNumberLibPath = "/usr/palm/frameworks/phonenumberlib/version/1.0/javascript";

var include1 = Qt.include(phoneNumberLibPath + "/PhoneNumberMetadata.js");
if(!include1.OK) {
    // it failed with on-device path, so try again with relative path (Qt Desktop situation)
    phoneNumberLibPath = Qt.resolvedUrl("../../../../loadable-frameworks/phonenumberlib/javascript");
    console.log("loading phonenumberlib from on-device default path failed, trying with: " + phoneNumberLibPath);
    Qt.include(phoneNumberLibPath + "/PhoneNumberMetadata.js");
}
Qt.include(phoneNumberLibPath + "/PhoneNumberNormalizer.js");
Qt.include(phoneNumberLibPath + "/PhoneNumber.js");

function normalizePhoneNumber(phoneNumber, countryCode)
{
    var phoneNumberObj = PhoneNumberLib.Parse(phoneNumber, countryCode);

    // try to be compatible with Enyo g11n
    if (phoneNumberObj) {
        // reverse of "+-countrycode--national_number_without_leading_digits-extension"
        var phoneNatNumberWithoutLeadingDigits = phoneNumberObj.nationalNumber.substr(phoneNumberObj.leadingDigit.length);

        var normalizedNumber = "+-"+phoneNumberObj.regionMetaData.countryCode + "-" + phoneNumberObj.leadingDigit + "-" + phoneNatNumberWithoutLeadingDigits + "-";
        var reversedNormalizedNumber = normalizedNumber.split("").reverse().join("");

        console.log("normalizePhoneNumber("+phoneNumber+")="+reversedNormalizedNumber);
        return reversedNormalizedNumber;
    }

    // worst case scenario: we couldn't parse the number. Fallback to
    console.log("ERROR: normalizePhoneNumber: couldn't parse "+phoneNumber+", returning locale-less normalization");
    return "-" + phoneNumber.split("").reverse().join("") + "---";
}
