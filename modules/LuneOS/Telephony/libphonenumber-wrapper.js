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
Qt.include("phonenumber.js/PhoneNumberMetadata.js");
Qt.include("phonenumber.js/PhoneNumberNormalizer.js");
Qt.include("phonenumber.js/PhoneNumber.js");

function normalizePhoneNumber(phoneNumber, countryCode)
{
    var phoneNumberObj = PhoneNumber.Parse(phoneNumber, countryCode);

    // try to be compatible with Enyo g11n

    // reverse of "+-countrycode--national_number-extension"

    var normalizedNumber = "+-"+phoneNumberObj.regionMetaData.countryCode + "--" + phoneNumberObj.nationalNumber + "-";
    var reversedNormalizedNumber = normalizedNumber.split("").reverse().join("");

    console.log("normalizePhoneNumber("+phoneNumber+")="+reversedNormalizedNumber);
    return reversedNormalizedNumber;
}
