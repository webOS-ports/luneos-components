import QtQuick 2.0

/**
 * Desktop mock of QOfonoSimManager.
 *
 * The SIM starts ready, so the app opens on the dialer. Set `pinRequired` to
 * SimPin (1) or SimPuk (9) to exercise the PIN and PUK screens; the mock
 * accepts "1234" as the PIN and "12345678" as the PUK and rejects anything
 * else, so the retry and error paths can be walked through without a modem.
 */
Item {
    id: simManager

    // Mirrors QOfonoSimManager::Error, in the same order as the real one.
    enum Error {
        NoError,
        NotImplementedError,
        InProgressError,
        InvalidArgumentsError,
        InvalidFormatError,
        FailedError,
        UnknownError
    }

    // Mirrors QOfonoSimManager::PinType.
    enum PinType {
        NoPin,
        SimPin,
        SimPin2,
        PhoneToSimPin,
        PhoneToFirstSimPin,
        NetworkPersonalizationPin,
        NetworkSubsetPersonalizationPin,
        ServiceProviderPersonalizationPin,
        CorporatePersonalizationPin,
        SimPuk,
        SimPuk2,
        PhoneToFirstSimPuk,
        NetworkPersonalizationPuk,
        NetworkSubsetPersonalizationPuk,
        CorporatePersonalizationPuk
    }

    /// The PIN the mock SIM accepts, and the PUK that unblocks it.
    property string mockPin: "1234"
    property string mockPuk: "12345678"

    property string modemPath: ""

    /// QOfonoObject exposes this on every interface: true once the modem's
    /// D-Bus interface has answered. A mock is always up, so it is always
    /// true -- but it has to exist, because callers watch it to tell a SIM
    /// that is really there from one still being asked about.
    property bool valid: true

    property bool present: true
    property string subscriberIdentity: "204040123456789"
    property string mobileCountryCode: "204"
    property string mobileNetworkCode: "04"
    property string serviceProviderName: "LuneOS Mock"
    property var subscriberNumbers: [ "+31612345678" ]
    property var serviceNumbers: ({})
    property string cardIdentifier: "8931440000000000001"
    property var preferredLanguages: [ "en" ]
    property bool fixedDialing: false
    property bool barredDialing: false

    /// NoPin, so the app is usable straight away.
    property int pinRequired: OfonoSimManager.NoPin
    property var lockedPins: []
    property var pinRetries: ({ "1": 3, "2": 3, "9": 10, "10": 10 })

    signal enterPinComplete(int error, string errorString)
    signal resetPinComplete(int error, string errorString)
    signal changePinComplete(int error, string errorString)
    signal lockPinComplete(int error, string errorString)
    signal unlockPinComplete(int error, string errorString)

    function isPukType(pinType) {
        return pinType === OfonoSimManager.SimPuk || pinType === OfonoSimManager.SimPuk2 ||
               pinType === OfonoSimManager.PhoneToFirstSimPuk ||
               pinType === OfonoSimManager.NetworkPersonalizationPuk ||
               pinType === OfonoSimManager.NetworkSubsetPersonalizationPuk ||
               pinType === OfonoSimManager.CorporatePersonalizationPuk;
    }

    function pukToPin(pukType) {
        if (pukType === OfonoSimManager.SimPuk) return OfonoSimManager.SimPin;
        if (pukType === OfonoSimManager.SimPuk2) return OfonoSimManager.SimPin2;
        return OfonoSimManager.SimPin;
    }

    function minimumPinLength(pinType) { return isPukType(pinType) ? 8 : 4; }
    function maximumPinLength(pinType) { return isPukType(pinType) ? 8 : 8; }

    function _spendRetry(pinType) {
        var retries = pinRetries;
        var left = retries[String(pinType)];
        if (left !== undefined && left > 0) {
            retries[String(pinType)] = left - 1;
            pinRetries = retries;
        }
    }

    function enterPin(pinType, pin) {
        if (pin === mockPin) {
            pinRequired = OfonoSimManager.NoPin;
            enterPinComplete(OfonoSimManager.NoError, "");
        } else {
            _spendRetry(pinType);
            enterPinComplete(OfonoSimManager.FailedError, "Incorrect PIN");
        }
    }

    function resetPin(pukType, puk, newPin) {
        if (puk === mockPuk) {
            mockPin = newPin;
            pinRequired = OfonoSimManager.NoPin;
            resetPinComplete(OfonoSimManager.NoError, "");
        } else {
            _spendRetry(pukType);
            resetPinComplete(OfonoSimManager.FailedError, "Incorrect PUK");
        }
    }

    function changePin(pinType, oldPin, newPin) {
        if (oldPin === mockPin) {
            mockPin = newPin;
            changePinComplete(OfonoSimManager.NoError, "");
        } else {
            changePinComplete(OfonoSimManager.FailedError, "Incorrect PIN");
        }
    }

    function lockPin(pinType, pin) {
        lockPinComplete(pin === mockPin ? OfonoSimManager.NoError : OfonoSimManager.FailedError, "");
    }

    function unlockPin(pinType, pin) {
        unlockPinComplete(pin === mockPin ? OfonoSimManager.NoError : OfonoSimManager.FailedError, "");
    }
}
