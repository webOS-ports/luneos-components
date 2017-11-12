import QtQuick 2.0

import "SecurityTypeEnum.js" as SecurityType;
import "EapMethodEnum.js" as EapMethod;

Item {
    id: networkService

    /*readonly*/ property string name: ""
    /*readonly*/ property string state: ""
    /*readonly*/ property string type: ""
    /*readonly*/ property string error: ""
    /*readonly*/ property variant /*QStringList*/ security: [""]
    /*readonly*/ property int /*SecurityType*/ securityType: SecurityType.SecurityNone
    /*readonly*/ property int strength: 0
    /*readonly*/ property bool favorite: false
    property bool autoConnect: false
    property string path: "/"
    /*readonly*/ property variant /*QVariantMap*/ ipv4: ({})
    property variant /*QVariantMap*/ ipv4Config: ({})
    /*readonly*/ property variant /*QVariantMap*/ ipv6: ({})
    property variant /*QVariantMap*/ ipv6Config: ({})
    /*readonly*/ property variant /*QStringList*/ nameservers: [ "local", "other" ]
    property variant /*QStringList*/ nameserversConfig: ["default"]
    /*readonly*/ property variant /*QStringList*/ domains: []
    property variant /*QStringList*/ domainsConfig: []
    /*readonly*/ property variant /*QVariantMap*/ proxy: ({})
    property variant /*QVariantMap*/ proxyConfig: ({})
    /*readonly*/ property variant /*QVariantMap*/ ethernet: ({})
    /*readonly*/ property bool roaming: false
    /*readonly*/ property bool connected: false
    /*readonly*/ property variant /*QStringList*/ timeservers: []
    property variant /*QStringList*/ timeserversConfig: []

    property int /*EapMethod*/ eapMethod: EapMethod.EapNone
    property string identity: ""
    property string passphrase: ""
    /*readonly*/ property bool eapMethodAvailable: false
    /*readonly*/ property bool identityAvailable: false
    /*readonly*/ property bool passphraseAvailable: false
    /*readonly*/ property string bssid: ""
    /*readonly*/ property int maxRate: 0
    /*readonly*/ property int frequency: 0
    /*readonly*/ property string encryptionMode: ""
    /*readonly*/ property bool hidden: false
    /*readonly*/ property bool available: false
    /*readonly*/ property bool managed: false
    /*readonly*/ property bool saved: false
    /*readonly*/ property bool connecting: false
    /*readonly*/ property string lastConnectError: ""

    /// signals
    signal serviceConnectionStarted();
    signal serviceDisconnectionStarted();
    signal propertiesReady();

    /// slots
    function requestConnect() {
        networkService.connecting = true;
        connectionTimer.start();
    }
    function requestDisconnect() {
    }
    function remove() {
    }
    function resetCounters() {
    }

    Timer {
        id: connectionTimer
        repeat: false; running: false; interval: 2000
        onTriggered: {
            networkService.connected = true;
            networkService.connecting = false;
        }
    }
}
