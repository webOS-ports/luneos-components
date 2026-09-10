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
    /*readonly*/ property bool available: name==="wifi" || name==="bluetooth" || name==="cellular"
    /*readonly*/ property bool connected: false
    property bool powered: name==="wifi" || name==="bluetooth" || name==="cellular"
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
    }
    function requestScan() {
    }

    /// signals
    signal technologiesChanged();
    signal scanRequestFinished();

    /*
     * A name, a strength and a padlock was all the network list ever asked
     * of these. WiFiPage's details page asks for the rest - what band it is
     * on, what the addressing came out as, which interface it is over - so
     * they carry it now, or the page comes up empty on the desktop and there
     * is nothing to develop it against.
     *
     * Only the connected one has addressing, because that is the shape
     * connman hands back: a service that is not up has no ipv4/ethernet to
     * report, just what the scan saw.
     */
    property list<NetworkService> _wifiServices: [
        NetworkService {
            type: "wifi"
            path: "/net/connman/service/wifi_009e959b585c_32xxxxx669_managed_psk"
            name: "My Own Wifi"
            securityType: NetworkService.SecurityPSK
            security: ["psk"]
            strength: 90
            connected: true
            state: "online"
            favorite: true
            saved: true
            autoConnect: true
            available: true
            managed: true
            bssid: "b4:fb:e4:11:22:33"
            frequency: 5180
            maxRate: 866700000
            encryptionMode: "aes"
            ipv4: ({"Method": "dhcp", "Address": "192.168.1.42",
                    "Netmask": "255.255.255.0", "Gateway": "192.168.1.1"})
            ipv6: ({"Method": "auto", "Address": "2001:db8:1234::42",
                    "PrefixLength": 64, "Gateway": "fe80::1"})
            nameservers: ["192.168.1.1", "1.1.1.1"]
            domains: ["lan"]
            proxy: ({"Method": "direct"})
            ethernet: ({"Method": "auto", "Interface": "wlan0",
                        "Address": "00:9e:95:9b:58:5c", "MTU": 1500})
        },
        NetworkService {
            type: "wifi"
            path: "/net/connman/service/wifi_009e959b585c_32xxxxx670_managed_psk"
            name: "Someone else's wifi"
            securityType: NetworkService.SecurityWEP
            security: ["wep"]
            strength: 30
            state: "idle"
            available: true
            managed: true
            bssid: "3c:a6:2f:44:55:66"
            frequency: 2437
            maxRate: 54000000
        },
        NetworkService {
            type: "wifi"
            path: "/net/connman/service/wifi_009e959b585c_32xxxxx670"
            name: "OpenBar Wifi"
            securityType: NetworkService.SecurityNone
            security: ["none"]
            strength: 50
            state: "idle"
            available: true
            managed: true
            bssid: "9a:02:7d:77:88:99"
            frequency: 2412
            maxRate: 144400000
        }
    ]
    property list<NetworkService> _cellularServices: [
        NetworkService {
            type: "cellular"
        }
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
        }
    }
}
