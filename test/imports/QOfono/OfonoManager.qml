import QtQuick 2.0

/// Desktop mock of QOfonoManager: one modem, always present.
Item {
    property string defaultModem: "/mock/modem0"
    property var modems: [ "/mock/modem0" ]
    property bool available: true

    signal modemAdded(string modem)
    signal modemRemoved(string modem)
}
