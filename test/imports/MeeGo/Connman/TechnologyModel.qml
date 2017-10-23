import QtQuick 2.9
import QtQml.Models 2.3

import "SecurityTypeEnum.js" as SecurityType;
import "EapMethodEnum.js" as EapMethod;

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
            path: "/net/connman/service/wifi_009e959b585c_32xxxxx669_managed_psk"
            name: "My Own Wifi"
            securityType: SecurityType.SecurityPSK
            strength: 90
            connected: true
        },
        NetworkService {
            type: "wifi"
            path: "/net/connman/service/wifi_009e959b585c_32xxxxx670_managed_psk"
            name: "Someone else's wifi"
            securityType: SecurityType.SecurityWEP
            strength: 30
        },
        NetworkService {
            type: "wifi"
            path: "/net/connman/service/wifi_009e959b585c_32xxxxx670"
            name: "OpenBar Wifi"
            securityType: SecurityType.SecurityNone
            strength: 50
        }
    ]
    property list<NetworkService> _cellularServices: [
        NetworkService {
            type: "cellular"
        }
    ]
    property list<NetworkService> _bluetoothServices: [
    ]

    Component.onCompleted: {
        _fillScanResults
    }
    onPoweredChanged: _fillScanResults();

    function _fillScanResults() {
        technologyModel.clear();
        if(technologyModel.powered) {
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
}
