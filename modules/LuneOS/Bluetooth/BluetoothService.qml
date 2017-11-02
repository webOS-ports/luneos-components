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
pragma Singleton

import QtQuick 2.0
import Connman 0.2
import Nemo.DBus 2.0

Item {
    id: bluetoothService

    readonly property bool powered: bluetoothTech.available && bluetoothTech.powered
    readonly property bool connected: bluetoothTech.available && bluetoothTech.connected
    readonly property bool isTurningOn: (bluetoothTech.available && bluetoothTech.powered) && (btAdapter.path === "/")
    property ListModel deviceModel: ListModel {}

    signal ready();

    TechnologyModel {
        id: bluetoothTech
        name: "bluetooth"
    }
    DBusInterface {
        id: btManager
        service: "org.bluez"
        path: "/"
        iface: "org.freedesktop.DBus.ObjectManager"
        bus: DBus.SystemBus
        signalsEnabled: true

        function interfacesAdded(path, interfaces) {
            console.log("interfacesAdded ! path = " + path);
            if(typeof interfaces["org.bluez.Adapter1"] !== 'undefined')
            {
                console.log("New adapter found: " + path);
                btAdapter.path = path;

                bluetoothService.ready();
            }
            else if(typeof interfaces["org.bluez.Device1"] !== 'undefined')
            {
                console.log("New device found: " + path);
                _createBtDevice(path)
            }
        }
        function interfacesRemoved(path, interfaces) {
            console.log("interfacesRemoved ! path = " + path);
            if(interfaces.indexOf("org.bluez.Adapter1")>=0 &&
               btAdapter.path === path)
            {
                btAdapter.path = "/";
                console.log("Adapter removed: " + path);
            }
            else if(interfaces.indexOf("org.bluez.Device1")>=0)
            {
                _removeBtDevice(path)
            }
        }
    }

    Component.onCompleted:  {
        console.log("calling GetManagedObjects...");
        btManager.typedCall('GetManagedObjects', [], function (result) {
            for(var newPath in result) {
                btManager.interfacesAdded(newPath, result[newPath]);
            }
        });
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

    function startDiscovery() {
        if(powered && !isTurningOn)
            btAdapter.call('StartDiscovery');
    }

    function stopDiscovery() {
        if(powered && !isTurningOn)
            btAdapter.call('StopDiscovery');
    }

    function _createBtDevice(path) {
        var device;
        for (var i=0;i<deviceModel.count;i++) {
            device = deviceModel.get(i).device;
            if (device.path === path) {
                console.log("Device already registered, skipping.");
                return;
            }
        }

        var deviceComponent = Qt.createComponent("BluetoothDevice.qml");
        if (deviceComponent.status === Component.Ready) {
            device = deviceComponent.createObject(bluetoothService, {path: path});
            deviceModel.append({device: device});
        }
        else {
            console.error("Error during instantiation of BluetoothDevice.qml!");
            console.error(deviceComponent.errorString());
        }
    }

    function _removeBtDevice(path) {
        for (var i=0;i<deviceModel.count;i++) {
            var device = deviceModel.get(i).device;
            if (device.path === path) {
                deviceModel.remove(i);
                device.destroy(1000); // give a delay to the UI before destroying the object
                console.log("Device removed: " + path);
                break;
            }
        }
    }
}
