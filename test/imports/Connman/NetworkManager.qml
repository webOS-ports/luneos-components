import QtQuick 2.9

Item {
    id: networkManager

    /*readonly*/ property bool available: true
    property string state: "default"
    property bool offlineMode: false
    /*readonly*/ property NetworkService defaultRoute: NetworkService {}

    property bool sessionMode: false
    property int inputRequestTimeout: 100

    property bool servicesEnabled: false
    property bool technologiesEnabled: false

    /*
     * The real DeclarativeNetworkManager spells these with a capital -
     * "WifiTechnology", not "wifiTechnology" - and a QML type cannot follow
     * it there, because QML refuses to declare a property whose name begins
     * with an upper case letter and C++ Q_PROPERTY is not bound by that rule.
     * So these names are not the ones a device answers to, and anything
     * reading networkManager.WifiTechnology gets undefined here however this
     * file is written - which reads as "the device has no Wi-Fi" rather than
     * as an error.
     *
     * technologyPathForType() below is the way round it: it exists on the
     * real type, means the same thing, and is spelled the same in both
     * places. Prefer it in new code.
     */
    /*readonly*/ property string wifiTechnology: "/net/connman/technology/wifi"
    /*readonly*/ property string cellularTechnology: "/net/connman/technology/cellular"
    /*readonly*/ property string bluetoothTechnology: "/net/connman/technology/bluetooth"
    /*readonly*/ property string gpsTechnology: "/net/connman/technology/gps"

    /*readonly*/ property bool valid: true
    /*readonly*/ property bool connected: true
    /*readonly*/ property bool connecting: false

    // Nothing is on the hotspot. An empty list rather than a populated one:
    // a page that showed "2 devices" on a desktop that is not sharing
    // anything would be showing something no device reports at rest.
    /*readonly*/ property var tetheringClients: []

    signal technologiesChanged()
    signal availabilityChanged(bool available)

    /*NetworkTechnology**/ function getTechnology(type) {
    }
    /*QStringList*/ function servicesList(tech) {
    }
    /*QStringList*/ function savedServicesList(tech) {
    }
    /*QStringList*/ function availableServices(tech) {
    }
    /*QStringList*/ function technologiesList() {
    }
    /*QString*/ function technologyPathForService(path) {
    }
    /*QString*/ function technologyPathForType(type) {
        // What a phone-shaped device reports. "gadget" is the USB network
        // gadget, which is how USB tethering is reached and which has no
        // named property of its own even on the real type.
        var known = ["wifi", "cellular", "bluetooth", "gps", "gadget"];
        return known.indexOf(type) >= 0 ? ("/net/connman/technology/" + type) : "";
    }

    /// slots
    function registerAgent(path) {
    }
    function unregisterAgent(path) {
    }
    function registerCounter(path, accuracy, period) {
    }
    function unregisterCounter(path) {
    }
    /*bool*/ function createService(/*QVariantMap*/ settings, tech, service, device) {
    }
    /*QString*/ function createServiceSync(/*QVariantMap*/ settings, tech, service, device) {
    }
}
