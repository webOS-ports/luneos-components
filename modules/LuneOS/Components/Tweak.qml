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

import LuneOS.Service 1.0

Item {
    id: tweak

    property string owner: ""
    property alias serviceName: service.name
    property string key: ""
    property variant value
    property variant defaultValue

    /*
     * Subscribed, so a value changed elsewhere (the Tweaks app, Settings'
     * Appearance page) reaches whoever reads it without a restart. A service
     * that does not know "subscribe" answers once, as before.
     *
     * Every reply comes through handleResult, the bus's own "service went
     * away" message too. Those carry no value, so the last one stays rather
     * than snapping back to the default. handleError is only reached when the
     * call cannot be made at all.
     *
     * The subscription ends with the service. The tweaks service is started
     * on demand, so it is called at once (which starts it) rather than waited
     * for, and the bus is watched: once it has gone and comes back, whoever
     * started it again, the key is subscribed to afresh.
     */
    property var _call: null
    property bool _lost: false

    readonly property string _tweaksService: "org.webosports.service.tweaks.prefs"

    function _subscribe() {
        if (_call)
            _call.cancel();
        _call = service.subscribe("luna://" + _tweaksService + "/get",
                                  JSON.stringify({owner: tweak.owner, keys: [tweak.key],
                                                  subscribe: true}),
                                  service.handleResult, service.handleError);
    }

    LunaService {
        id: service
        onInitialized: {
            tweak._subscribe();
            service.subscribe("luna://com.webos.service.bus/signal/registerServerStatus",
                              JSON.stringify({serviceName: tweak._tweaksService}),
                              handleStatus, function (message) {});
        }

        function handleResult(message) {
            var response = JSON.parse(message.payload);
            if (response[tweak.key] !== undefined)
                tweak.value = response[tweak.key];
        }

        function handleError(message) {
            tweak.value = tweak.defaultValue;
        }

        function handleStatus(message) {
            var response = JSON.parse(message.payload);
            if (response.connected === false) {
                tweak._lost = true;
            } else if (response.connected === true && tweak._lost) {
                tweak._lost = false;
                tweak._subscribe();
            }
        }
    }

    Component.onCompleted: value = defaultValue;
}
