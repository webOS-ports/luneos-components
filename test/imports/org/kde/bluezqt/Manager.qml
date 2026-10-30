pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick

/*
 * Enough of BluezQt's Manager for LuneOS.Bluetooth's BluetoothManager: one
 * adapter whose discovery the tests can watch, and devices to pair and
 * connect. Every call is logged in "calls" and its PendingCall kept in
 * "pending" for the test to finish. reset() starts over.
 */
QtObject {
    id: manager

    property bool operational: true
    property QtObject usableAdapter: adapter

    property var calls: []
    property var pending: []
    property var devices: ({})

    readonly property var adapter: QtObject {
        property bool discovering: false
        property bool discoverable: false
        function startDiscovery() { manager._log("startDiscovery"); discovering = true; return manager._pending(); }
        function stopDiscovery() { manager._log("stopDiscovery"); discovering = false; return manager._pending(); }
    }

    property Component _deviceComponent: Component {
        QtObject {
            property string address
            property bool paired: false
            property bool trusted: false
            property bool connected: false
            function pair() { manager._log("pair " + address); return manager._pending(); }
            function connectToDevice() { manager._log("connect " + address); return manager._pending(); }
            function disconnectFromDevice() { manager._log("disconnect " + address); return manager._pending(); }
        }
    }
    property Component _callComponent: Qt.createComponent("FakePendingCall.qml")

    function deviceForAddress(address) {
        if (!devices[address])
            devices[address] = _deviceComponent.createObject(manager, { address: address });
        return devices[address];
    }

    function _log(what) { calls = calls.concat([what]); }
    function _pending() {
        var call = _callComponent.createObject(manager);
        pending = pending.concat([call]);
        return call;
    }

    function reset() {
        calls = [];
        pending = [];
        devices = {};
        operational = true;
        usableAdapter = adapter;
        adapter.discovering = false;
    }
}
