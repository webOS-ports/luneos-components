/*
 * (c) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick

/*
 * com.webos.service.bluetooth2 for tst_bluetooth_manager.qml, in place of a
 * LunaService: call() and subscribe() as LunaService has them, answered
 * later (from the event loop, as the bus does) and recorded.
 *
 *  - adapter/getStatus and device/getStatus subscriptions get "adapters"
 *    and "devices" at once and again whenever the test changes them;
 *  - a call is answered by answers[method] (a function of the arguments
 *    returning the reply, or null to hold it), {"returnValue": true} if
 *    there is none; a held call is answered with answerHeld();
 *  - push(method, reply) sends a reply to the open subscriptions of a
 *    method, as adapter/pair and adapter/awaitPairingRequests do.
 * method is what follows "luna://com.webos.service.bluetooth2/".
 */
QtObject {
    id: bus

    property string name: ""

    property var adapters: [{"adapterAddress": "00:00:46:01:2a:a1", "powered": true,
                             "discovering": false, "discoverable": false}]
    property var devices: []
    property var answers: ({})
    // method -> replies the next subscriptions get as their first reply instead of
    // {"returnValue": true, "subscribed": true}, one each, in order.
    property var refusals: ({})

    // Every call and subscribe, in order: {method, args, subscription}
    property var calls: []
    property var held: []
    property var subscriptions: []

    readonly property string prefix: "luna://com.webos.service.bluetooth2/"

    property var _queue: []
    property Timer _deliver: Timer {
        interval: 0
        onTriggered: {
            var queue = bus._queue;
            bus._queue = [];
            for (var i = 0; i < queue.length; i++)
                queue[i]();
            if (bus._queue.length > 0)
                start();
        }
    }

    function _later(fn) {
        _queue = _queue.concat([fn]);
        _deliver.start();
    }

    function _method(uri) {
        return uri.indexOf(prefix) === 0 ? uri.substring(prefix.length) : uri;
    }

    function _send(callback, reply) {
        if (callback)
            callback({"payload": JSON.stringify(reply)});
    }

    function reset() {
        adapters = [{"adapterAddress": "00:00:46:01:2a:a1", "powered": true,
                     "discovering": false, "discoverable": false}];
        devices = [];
        answers = ({});
        calls = [];
        held = [];
        subscriptions = [];
    }

    function call(uri, args, onReply, onError) {
        var method = _method(uri);
        var parsed = JSON.parse(args);
        calls = calls.concat([{"method": method, "args": parsed, "subscription": false}]);
        var answer = answers[method];
        var reply = answer ? answer(parsed) : {"returnValue": true};
        if (reply === null) {
            held = held.concat([{"method": method, "args": parsed, "onReply": onReply}]);
        } else {
            _later(function () { bus._send(onReply, reply); });
        }
        return {"cancel": function () { }};
    }

    function answerHeld(method, reply) {
        for (var i = 0; i < held.length; i++) {
            if (held[i].method === method) {
                var call = held[i];
                held = held.slice(0, i).concat(held.slice(i + 1));
                _send(call.onReply, reply);
                return true;
            }
        }
        return false;
    }

    function subscribe(uri, args, onReply, onError) {
        var method = _method(uri);
        var subscription = {"method": method, "args": JSON.parse(args), "onReply": onReply, "cancelled": false};
        subscription.cancel = function () { subscription.cancelled = true; };
        calls = calls.concat([{"method": method, "args": subscription.args, "subscription": true}]);
        subscriptions = subscriptions.concat([subscription]);
        if (method === "adapter/getStatus")
            _later(function () { bus._status(subscription); });
        else if (method === "device/getStatus")
            _later(function () { bus._status(subscription); });
        else
        {
            var first = {"returnValue": true, "subscribed": true};
            var queued = refusals[method];
            if (queued && queued.length > 0) {
                first = queued[0];
                var rest = Object.assign({}, refusals);
                rest[method] = queued.slice(1);
                refusals = rest;
            }
            _later(function () {
                if (!subscription.cancelled)
                    bus._send(onReply, first);
            });
        }
        return subscription;
    }

    function _status(subscription) {
        if (subscription.cancelled)
            return;
        if (subscription.method === "adapter/getStatus")
            _send(subscription.onReply, {"returnValue": true, "subscribed": true, "adapters": adapters});
        else
            _send(subscription.onReply, {"returnValue": true, "subscribed": true, "devices": devices});
    }

    onAdaptersChanged: _later(function () { bus._resend("adapter/getStatus"); })
    onDevicesChanged: _later(function () { bus._resend("device/getStatus"); })

    function _resend(method) {
        for (var i = 0; i < subscriptions.length; i++) {
            if (subscriptions[i].method === method)
                _status(subscriptions[i]);
        }
    }

    // A reply on every open subscription of method.
    function push(method, reply) {
        for (var i = 0; i < subscriptions.length; i++) {
            if (subscriptions[i].method === method && !subscriptions[i].cancelled)
                _send(subscriptions[i].onReply, reply);
        }
    }

    function open(method) {
        return subscriptions.filter(function (s) { return s.method === method && !s.cancelled; }).length;
    }

    function count(method) {
        return calls.filter(function (c) { return c.method === method; }).length;
    }

    function last(method) {
        for (var i = calls.length - 1; i >= 0; i--) {
            if (calls[i].method === method)
                return calls[i].args;
        }
        return null;
    }

    // A device as device/getStatus has it.
    function device(address, props) {
        var d = {"address": address, "name": "Device " + address.substring(address.length - 2),
                 "paired": false, "trusted": false, "blocked": false, "connected": false,
                 "connectedProfiles": [], "classOfDevice": 0, "rssi": 0,
                 "adapterAddress": "00:00:46:01:2a:a1"};
        for (var key in props)
            d[key] = props[key];
        return d;
    }

    function setDevice(address, props) {
        var list = [];
        var found = false;
        for (var i = 0; i < devices.length; i++) {
            var d = devices[i];
            if (d.address === address) {
                var copy = {};
                for (var k in d)
                    copy[k] = d[k];
                for (k in props)
                    copy[k] = props[k];
                d = copy;
                found = true;
            }
            list.push(d);
        }
        if (!found)
            list.push(device(address, props));
        devices = list;
    }

    function setAdapter(props) {
        var copy = {};
        for (var k in adapters[0])
            copy[k] = adapters[0][k];
        for (k in props)
            copy[k] = props[k];
        adapters = [copy].concat(adapters.slice(1));
    }
}
