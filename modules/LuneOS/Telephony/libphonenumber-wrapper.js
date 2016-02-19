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
var phoneNumberLibPath = "/usr/palm/frameworks/phonenumberlib/version/1.0";

var include1 = Qt.include(phoneNumberLibPath + "/javascript/PhoneNumberMetadata.js");
if(include1.status !== include1.OK) {
    // it failed with on-device path, so try again with relative path (Qt Desktop situation)
    phoneNumberLibPath = Qt.resolvedUrl("../../../../loadable-frameworks/phonenumberlib");
    console.log("loading phonenumberlib from on-device default path failed, trying with: " + phoneNumberLibPath);
    Qt.include(phoneNumberLibPath + "/javascript/PhoneNumberMetadata.js");
}
Qt.include(phoneNumberLibPath + "/javascript/PhoneNumberNormalizer.js");
Qt.include(phoneNumberLibPath + "/javascript/PhoneNumber.js");

PhoneNumberLib.setRootDir(phoneNumberLibPath);

// vCard stuff is using these types. Make sure if you change anything on this
// that the tests for vCard don't fail. Otherwise the rath of a million sand flies
// will overtake your shorts!
// prefixing these with "type_" to discourage direct display of these values
var PhoneNumberType = {
    "type_mobile" : "MOBILE",
    "type_home" : "HOME",
    "type_home2" : "HOME2",
    "type_work" : "WORK",
    "type_work2" : "WORK2",
    "type_main" : "MAIN",
    "type_personal_fax" : "PERSONAL_FAX",
    "type_work_fax" : "WORK_FAX",
    "type_pager" : "PAGER",
    "type_personal" : "PERSONAL",
    "type_sim" : "SIM",
    "type_assistant" : "ASSISTANT",
    "type_car" : "CAR",
    "type_radio" : "RADIO",
    "type_company" : "COMPANY",
    "type_other" : "OTHER"
};

function getPhoneNumberTypeStr(phoneNumberType) {
    if( PhoneNumberType.hasOwnProperty(phoneNumberType) ) {
        return PhoneNumberType[phoneNumberType];
    }

    return "OTHER";
}

function formatPhoneNumberForDisplay(phoneNumber, countryCode)
{
    var phoneNumberObj = PhoneNumberLib.Parse(phoneNumber, countryCode);

    if( phoneNumberObj )
    {
        if( phoneNumber[0] === '+' && phoneNumberObj.internationalFormat ) return phoneNumberObj.internationalFormat;
        if( phoneNumberObj.nationalFormat ) return phoneNumberObj.nationalFormat
    }
    return phoneNumber;
}

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

function getNumberGeolocation(phoneNumber, countryCode, cb)
{
    if(typeof cb !== 'function') return;

    var phoneNumberObj = PhoneNumberLib.Parse(phoneNumber, countryCode);
    if(phoneNumberObj &&
       phoneNumberObj.internationalNumber &&
       phoneNumberObj.regionMetaData && phoneNumberObj.regionMetaData.countryCode) {
        PhoneNumberLib.GetGeolocation(phoneNumberObj.internationalNumber, cb);
    }
    else {
        cb("Unknown");
    }
}
