import QtQuick 2.0

Item {
    id: networkSession

    readonly property string state: "default"
    readonly property string name: ""
    readonly property string bearer: ""
    readonly property string sessionInterface: ""
    readonly property variant /*QVariantMap*/ ipv4: ({})
    readonly property variant /*QVariantMap*/ ipv6: ({})
}
