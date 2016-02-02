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
    console.log("ERROR: normalizePhoneNumber: couldn't parse "+phoneNumber+" !");
    return "-" + phoneNumber.split("").reverse().join("") + "---";
}
