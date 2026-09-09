import QtQuick 2.0

import "EapMethodEnum.js" as EapMethod;

Item {
    id: networkService

    /*
     * The real NetworkService is a C++ type whose SecurityType is a Q_ENUM,
     * so QML reads the values off the type itself - NetworkService.SecurityPSK.
     * SecurityTypeEnum.js could not stand in for that: a plain QML Item
     * carries no enum, so against this stub every such comparison came out
     * undefined and quietly did the wrong thing. WiFiPage's lock icon
     * (securityType !== NetworkService.SecurityNone) showed on open networks
     * for exactly that reason. Declared as a QML enum, the stub now answers
     * the way the plugin does.
     *
     * Values match libconnman-qt's NetworkService::SecurityType.
     */
    enum SecurityType {
        SecurityUnknown = 0,
        SecurityNone = 1,
        SecurityWEP = 2,
        SecurityPSK = 3,
        SecurityIEEE802 = 4
    }

    /*readonly*/ property string name: ""
    /*readonly*/ property string state: ""
    /*readonly*/ property string type: ""
    /*readonly*/ property string error: ""
    /*readonly*/ property variant /*QStringList*/ security: [""]
    /*readonly*/ property int /*SecurityType*/ securityType: NetworkService.SecurityNone
    /*readonly*/ property int strength: 0
    /*readonly*/ property bool favorite: false
    property bool autoConnect: false
    property string path: "/"
    /*readonly*/ property variant /*QVariantMap*/ ipv4: ({})
    property variant /*QVariantMap*/ ipv4Config: ({})
    /*readonly*/ property variant /*QVariantMap*/ ipv6: ({})
    property variant /*QVariantMap*/ ipv6Config: ({})
    // Empty until the service is actually up, as connman has it: these are
    // the nameservers in use, not the configured ones. The placeholder pair
    // that used to sit here showed up as a DNS row on networks that were not
    // even connected.
    /*readonly*/ property variant /*QStringList*/ nameservers: []
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
