/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
 * Copyright (C) 2015 Nikolay Nizov <nizovn@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import MeeGo.Connman 0.2
import Nemo.DBus 2.0

Item {
    id: bluetoothService

    property bool powered: bluetoothTech.available && bluetoothTech.powered
    property bool connected: bluetoothTech.available && bluetoothTech.connected
    property var devicesList: []
    property bool isTurningOn: (bluetoothTech.available && bluetoothTech.powered) && (btAdapter.path === "/")
    property ListModel deviceModel: ListModel {}

    signal clearBtList()
    signal addBtEntry(string name, string address, int cod, string connStatus, bool connected)
    signal updateBtEntry(string address, string connStatus, bool connected)
    signal setBtState(bool isOn, bool turningOn, string state)

    TechnologyModel {
        id: bluetoothTech
        name: "bluetooth"
        available: true
    }
    DBusInterface {
        id: btManager
        service: "org.bluez"
        path: "/"
        iface: "org.freedesktop.DBus.ObjectManager"
        bus: DBus.SystemBus
        signalsEnabled: true

        function interfacesAdded(path, interfaces) {
            if(typeof interfaces["org.bluez.Adapter1"] !== 'undefined')
            {
                console.log("New adapter found: " + path);
                btAdapter.path = path;
            }
            else if(typeof interfaces["org.bluez.Device1"] !== 'undefined')
            {
                console.log("New device found: " + path);
                createBtDevice(path)
            }
        }
        function interfacesRemoved(path, interfaces) {
            if(typeof interfaces["org.bluez.Adapter1"] !== 'undefined' &&
               btAdapter.path === adapter)
            {
                console.log("Adapter removed: " + path);
                btAdapter.path = "/";
            }
            else if(typeof interfaces["org.bluez.Device1"] !== 'undefined')
            {
                console.log("Device removed: " + path);
                removeBtDevice(path)
            }
        }

        Component.onCompleted: {
            console.log("calling GetManagedObjects...");
            btManager.typedCall('GetManagedObjects', [], function (result) {
                for(path in result) {
                    interfacesAdded(path, result[path]);
                }
            });
        }
    }

    DBusInterface {
        id: btAdapter
        service: "org.bluez"
        path: "/"
        iface: "org.bluez.Adapter1"
        bus: DBus.SystemBus
        signalsEnabled: false
    }

    function setPowered(powered) {
        if (!bluetoothTech.available) return;

        if (bluetoothTech.powered !== powered)
            bluetoothTech.powered = powered;
    }

    function disconnectAllBtMenuProfiles(address) {
        for (var i=0;i<deviceModel.count;i++) {
            var device = deviceModel.get(i).device;
            if (device.address === address) {
                device.disconnectDevice();
            }
        }
    }

    function connectBtDevice(address, cod) {
        for (var i=0;i<deviceModel.count;i++) {
            var device = deviceModel.get(i).device;
            if (device.address === address) {
                device.connectDevice();
            }
        }
    }

    function createBtDevice(devicePath) {
        var deviceComponent = Qt.createComponent("BluetoothDevice.qml");
        if (deviceComponent.status === Component.Ready) {
            var device = deviceComponent.createObject(bluetoothService, {path: devicePath});
            deviceModel.append({device: device});
        }
        else {
            console.error("Error during instantiation of BluetoothDevice.qml!");
            console.error(deviceComponent.errorString());
        }
    }

    function _clearBtList() {
        for (var i=0;i<deviceModel.count;i++) {
            var item = deviceModel.get(i).device;
            item.destroy();
        }
        deviceModel.clear();
        clearBtList();
    }

    onDevicesListChanged: {
        _clearBtList();
        for (var i=0;i<devicesList.length;i++) {
            createBtDevice(devicesList[i]);
        }
    }

    function updateBtState() {
        var state = bluetoothService.powered?"ON":"OFF";
        if (isTurningOn) state = "INIT";
        setBtState(bluetoothService.powered, isTurningOn, state);
    }

    onIsTurningOnChanged: {
        updateBtState();
    }

    onPoweredChanged: {
        if (!powered)
            _clearBtList();
        updateBtState();
    }

    Component.onCompleted: {
        updateBtState();
    }
}
