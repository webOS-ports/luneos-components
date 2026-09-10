import QtQuick 2.0

/// Desktop mock of QOfonoCellBroadcast.
///
/// "topics" is ofono's own spelling of the subscription: a comma-separated
/// list whose entries are either one channel or a "from-to" range. It starts
/// empty and cell broadcast starts off, which is the state of a device nobody
/// has been through this panel on - ofono does not enable the interface by
/// itself.
/// A QtObject and not an Item, unlike its neighbours here: the real
/// QOfonoCellBroadcast has an "enabled" property, and Item has one too, so an
/// Item-based mock shadows it and Qt warns about the override on every run.
QtObject {
    id: cellBroadcast

    property string modemPath: ""
    property bool valid: true

    property bool enabled: false
    property string topics: ""

    signal incomingBroadcast(string text, int topic)
    signal emergencyBroadcast(string text, var properties)
    signal reportError(string errorString)
}
