.pragma library

var modules = modules || {};
Qt.include("libphonenumber.js");

// Only some simple wrappers around libphonenumber.js to easily use it from QML
var PhoneNumberFormat = i18n.phonenumbers.PhoneNumberFormat;
var PhoneNumberUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
