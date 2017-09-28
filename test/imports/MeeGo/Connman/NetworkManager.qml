import QtQuick 2.0

Item {
    id: networkManager

    readonly property bool available: true
    property string state: "default"
    property bool offlineMode: false
    readonly property NetworkService defaultRoute: NetworkService {}

    property bool sessionMode: false
    property int inputRequestTimeout: 100

    property bool servicesEnabled: false
    property bool technologiesEnabled: false

    readonly property string WifiTechnology: "wifi"
    readonly property string CellularTechnology: "cellular"
    readonly property string BluetoothTechnology: "bluetooth"
    readonly property string GpsTechnology: "positionning"

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
}
