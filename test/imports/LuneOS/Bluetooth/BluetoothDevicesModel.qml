/*
 * Copyright (C) 2017 Christophe Chapuis <chris.chapuis@gmail.com>
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

// Just a simple namespace wrapper
ListModel {
    property int filterRole
    property var filterRegExp

    Component.onCompleted: {
        append({
            "Address": "22-BB-CC-00-11-22", "Name": "", "Paired": false, "Connected": false
        });
        append({
            "Address": "22-BB-CC-00-11-22", "Name": "Fake", "Paired": false, "Connected": false
        });
        append({
            "Address": "11-BB-CC-00-11-22", "Name": "Fake Paired", "Paired": true, "Connected": false
        });
        append({
            "Address": "44-BB-CC-00-11-22", "Name": "Fake Connected", "Paired": false, "Connected": true
        });
        append({
            "Address": "33-BB-CC-00-11-22", "Name": "Fake Paired Connected", "Paired": true, "Connected": true
        });
    }
}
