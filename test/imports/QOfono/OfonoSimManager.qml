import QtQuick 2.0

Item {
    id: ofonoSimManager

    property string modemPath
    property int pinRequired: 1
    property var pinRetries: { "0": 3,
                               "1": 3,
                               "2": 3,
                               "3": 3,
                               "4": 3,
                               "5": 3,
                               "6": 3,
                               "7": 3,
                               "8": 3,
                               "9": 3,
                               "10": 3,
                               "11": 3,
                               "12": 3,
                               "13": 3,
                               "14": 3
                             }
    property var lockedPins: [ 3, 4 ]
    property string subscriberIdentity: ""
    property string mobileCountryCode: "208"
    property string mobileNetworkCode: ""
    property var serviceNumbers: ({})
    property var subscriberNumbers: [ "123" ]
    property string cardIdentifier: "2563212345678906583"
    property bool present: true

    signal enterPinComplete(int error, string errorString)
    signal resetPinComplete(int error, string errorString)

    function minimumPinLength(pinType) {
        return 4;
    }

    function maximumPinLength(pinType) {
        return 4;
    }

    function isPukType(pinType) {
        return false;
    }

    function enterPin(pinType, pin) {
        enterPinComplete(0, "");
    }

    function resetPin(pinType, puk, pin) {
        resetPinComplete(0, "");
    }
}
