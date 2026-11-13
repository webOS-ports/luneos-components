/*
 * Copyright (C) 2017 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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

import "BluetoothPolicy.js" as Policy

/*
 * The devices the adapter knows, paired or found, one row each, with the
 * roles BluezQt's DevicesModel had (Address, Name, FriendlyName, Paired,
 * Connected, ... - BluetoothPolicy.js lists them).
 *
 * filterRole and filterRegularExpression keep only some rows, as on
 * BluezQt's QSortFilterProxyModel: filterRole 256 + 109 (Paired) with
 * filterRegularExpression /true/ lists the paired devices.
 */
ListModel {
    id: model

    // Stand-in in the tests.
    property QtObject manager: BluetoothManager

    property int filterRole: 0
    property var filterRegularExpression: null

    property QtObject _manager: null

    function _sync() {
        Policy.syncRows(model, manager ? manager.devices : [], filterRole, filterRegularExpression);
    }

    function _follow() {
        if (_manager)
            _manager.devicesChanged.disconnect(_sync);
        _manager = manager;
        if (_manager)
            _manager.devicesChanged.connect(_sync);
        _sync();
    }

    onManagerChanged: _follow()
    onFilterRoleChanged: _sync()
    onFilterRegularExpressionChanged: _sync()
    Component.onCompleted: _follow()
    Component.onDestruction: {
        if (_manager)
            _manager.devicesChanged.disconnect(_sync);
    }
}
