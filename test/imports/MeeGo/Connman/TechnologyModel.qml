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

ListModel { // should it inherit something else ? it looks like it holds a list of NetworkService
    id: technologyModel

    property string name: ""
    /*readonly*/ property bool available: false
    /*readonly*/ property bool connected: false
    property bool powered: false
    /*readonly*/ property bool scanning: false
    /*readonly*/ property bool changesInhibited: false
    property int filter: 0

    /*int*/ function indexOf(dbusObjectPath) {
    }
    /*NetworkService **/ function get(index) {
        if(technologyModel.name === "wifi") {
            return _wifiServices[index];
        }
        else if(technologyModel.name === "cellular") {
            return _cellularServices[index];
        }
        else if(technologyModel.name === "bluetooth") {
            return _bluetoothServices[index];
        }
    }
    function requestScan() {
    }

    /// signals
    signal technologiesChanged();
    signal scanRequestFinished();

    property list<NetworkService> _wifiServices: [
        NetworkService {
            type: "wifi"
            name: "wifi_1_xxxxxxx_managed_psk"
        },
        NetworkService {
            type: "wifi"
            name: "wifi_2_xxxxxxx_managed_wep"
        }
    ]
    property list<NetworkService> _cellularServices: [
        NetworkService {
            type: "cellular"
        }
    ]
    property list<NetworkService> _bluetoothServices: [
        NetworkService {
            type: "bluetooth"
        }
    ]

    Component.onCompleted: {
        if(technologyModel.name === "wifi") {
            for(var s in _wifiServices) {
                technologyModel.append({ "object": _wifiServices[s] });
            }
        }
        else if(technologyModel.name === "cellular") {
            for(var s in _cellularServices) {
                technologyModel.append({ "object": _cellularServices[s] });
            }
            technologyModel.append(cellularService1.createObject());
        }
        else if(technologyModel.name === "bluetooth") {
            for(var s in _bluetoothServices) {
                technologyModel.append({ "object": _bluetoothServices[s] });
            }
        }
    }
}
