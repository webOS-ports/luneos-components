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

    property bool powered: bluetoothTech.available && bluetoothTech.powered
    property bool connected: bluetoothTech.available && bluetoothTech.connected
    property bool isTurningOn: (bluetoothTech.available && bluetoothTech.powered) && (btAdapter.path === "/")
    property ListModel deviceModel: ListModel {}

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
               btAdapter.path === path)
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

    function startDiscovery() {
        if(powered && !isTurningOn)
            btAdapter.call('StartDiscovery');
    }

    function stopDiscovery() {
        if(powered && !isTurningOn)
            btAdapter.call('StopDiscovery');
    }
}
