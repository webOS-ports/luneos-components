import QtQuick 2.9
import QtQml.Models 2.3

/*
 * Usage:
    TechnologyModel {
        id: wifimodel
        name: "wifi"
    }

    @see https://github.com/nemomobile-ux/glacier-home/blob/master/src/qml/statusbar/WifiPanel.qml
 */

ObjectModel { // should it inherit something else ? it looks like it holds a list of NetworkService
    id: technologyModel

    Component {
        id: wifiService1
        NetworkService {
            type: "wifi"
            name: "wifi_1_xxxxxxx_managed_psk"
        }
    }
    Component {
        id: wifiService2
        NetworkService {
            type: "wifi"
            name: "wifi_2_xxxxxxx_managed_wep"
        }
    }
    Component {
        id: cellularService1
        NetworkService {
            type: "cellular"
        }
    }
    Component {
        id: bluetoothService1
        NetworkService {
            type: "bluetooth"
        }
    }

    Component.onCompleted: {
        if(technologyModel.name === "wifi") {
            technologyModel.append(wifiService1.createObject());
            technologyModel.append(wifiService2.createObject());
        }
        else if(technologyModel.name === "cellular") {
            technologyModel.append(cellularService1.createObject());
        }
        else if(technologyModel.name === "bluetooth") {
            technologyModel.append(bluetoothService1.createObject());
        }
    }

    property string name: ""
    readonly property bool available: false
    readonly property bool connected: false
    property bool powered: false
    readonly property bool scanning: false
    property bool changesInhibited: false
    property int filter: false

    /*int*/ function indexOf(dbusObjectPath) {
    }
    function requestScan() {
    }

    /// signals
    signal technologiesChanged();
    signal scanRequestFinished();
}
