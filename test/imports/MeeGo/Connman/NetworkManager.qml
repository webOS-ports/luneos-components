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

    /*readonly*/ property string WifiTechnology: "/net/connman/technology/wifi"
    /*readonly*/ property string CellularTechnology: "/net/connman/technology/cellular"
    /*readonly*/ property string BluetoothTechnology: "/net/connman/technology/bluetooth"
    /*readonly*/ property string GpsTechnology: "/net/connman/technology/gps"

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
