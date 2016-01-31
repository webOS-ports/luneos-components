.pragma library

var modules = modules || {};
Qt.include("libphonenumber.js");

// Only some simple wrappers around libphonenumber.js to easily use it from QML
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
