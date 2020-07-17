import QtQuick 2.0

Item {
    id: ofonoManager

    property string defaultModem: "/dummy_ril_0"
    property variant modems: [ "/dummy_ril_0", "/dummy_ril_1" ]

    property bool available: true

    signal modemAdded
    signal modemRemoved
}
