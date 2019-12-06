/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2014 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2016 Herman van Hazendonk <github.com@herrie.org>
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
import LuneOS.Components 1.0
import LuneOS.Service 1.0


Item {
    id: tweak

    property string owner: ""
    property alias serviceName: service.name
    property string key: ""
    property variant value
    property variant defaultValue

    LunaService {
        id: service
        onInitialized: {
            service.call("luna://org.webosports.service.tweaks.prefs/get",
                         JSON.stringify({owner: tweak.owner, keys: [tweak.key]}),
                         handleResult, handleError)
        }

        function handleResult(message) {
            var response = JSON.parse(message.payload);
            if (response[tweak.key] !== undefined)
                tweak.value = response[tweak.key];
        }

        function handleError(message) {
            tweak.value = tweak.defaultValue;
        }
    }

    Component.onCompleted: value = defaultValue;
}
