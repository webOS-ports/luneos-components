/*
 * Copyright (C) 2014 Roshan Gunasekara <roshan@mobileteck.com>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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

import QtQuick 2.1

import "db8content.js" as DB8

ListModel {
    id: testDb8Model
    property string kind: ""
    property bool watch: false
    property variant query: null
    // As the real one's: every page (the stand-in has no pages), the
    // status, db8's error.
    property bool allPages: false
    property string status: kind === "" ? "null" : "loading"
    property string errorText: ""
    property int errorCode: 0

    signal error(string errorText, int errorCode)

    // The rows as plain objects: get() hands them out as the real model
    // does (a ListModel would turn an array in a row into a model).
    property var _rows: []
    property string _listening: ""
    // One function to register and unregister with the store: the same
    // object both times, so a model that goes stops being told.
    property var _listener: function() { if (testDb8Model) testDb8Model.syncDb8Model(); }

    function get(index)
    {
        return _rows[index];
    }

    onQueryChanged: {
        syncDb8Model();
    }

    // A kind set after creation is listened to and read too.
    property bool _registered: false

    // Listens to one kind, once: a kind given in the declaration arrives
    // both here and at completion.
    function _listen(k) {
        if (_registered && _listening === k)
            return;
        if (_registered)
            DB8.unregisterListener(_listening, _listener);
        _listening = k;
        DB8.initDb8Kind(k, _listener);
        _registered = true;
    }

    onKindChanged: {
        _listen(kind);
        syncDb8Model();
    }

    Component.onCompleted: _listen(kind)
    Component.onDestruction: if (_registered) DB8.unregisterListener(_listening, _listener);

    // db8's reply, to the optional callback as the real model hands it.
    function _reply(callback, reply)
    {
        if (typeof callback === "function")
            callback(reply);
    }

    function _ids(dataArray)
    {
        var out = [];
        for (var i = 0; i < dataArray.length; ++i)
            out.push({ "id": dataArray[i]._id, "rev": 1 });
        return out;
    }

    function put(dataArray, callback)
    {
        DB8.initDb8Kind(testDb8Model.kind, function() {});
        DB8.put(testDb8Model.kind, dataArray);
        _reply(callback, { "returnValue": true, "results": _ids(dataArray) });
    }

    function putOnKind(forcedKind, dataArray, callback)
    {
        DB8.initDb8Kind(forcedKind, function() {});
        DB8.put(forcedKind, dataArray);
        _reply(callback, { "returnValue": true, "results": _ids(dataArray) });
    }

    function putKind(kindDefinition, callback)
    {
        DB8.initDb8Kind(kindDefinition.id, function() {});
        _reply(callback, { "returnValue": true });
    }

    function refresh()
    {
        testDb8Model.status = "loading";
        syncDb8Model();
    }

    function setTestDataFile(filePath) {
        if( DB8.testDataFileParsed.indexOf(filePath)>=0 ) {
            // just get in sync with the db if needed and return
            if( testDb8Model.count === 0 ) {
                syncDb8Model();
            }
            return;
        }
        DB8.testDataFileParsed.push(filePath);

        // Read the configuation file
        var xhr = new XMLHttpRequest;
        xhr.open("GET", filePath);
        xhr.onreadystatechange = function() {
            if( xhr.readyState === XMLHttpRequest.DONE ) {
                var dataArray = { data: [] };
                if( xhr.responseText ) {
                    var myResponse = xhr.responseText;
                    dataArray = JSON.parse(xhr.responseText);
                }

                put(dataArray.data);
            }
        }
        xhr.send();
    }

    function del(ids, callback)
    {
        var count = DB8.del(testDb8Model.kind, ids, undefined);
        _reply(callback, { "returnValue": true, "count": count });
    }

    function merge(dataArray, callback)
    {
        var count = DB8.merge(testDb8Model.kind, dataArray);
        _reply(callback, { "returnValue": true, "count": count });
    }

    function syncDb8Model() {
        // Parse _internalDb and try to apply the query.
        // Filtering understands every clause in the where array, dotted
        // property paths ("capabilityProviders.capability") and arrays along
        // the way, which is what the accounts and contacts queries need.

        if( !testDb8Model.query || testDb8Model.kind === "" ) return;

        var orderByProp = testDb8Model.query.orderBy;
        var ascending = !testDb8Model.query.desc;

        var result = [];

        var dbContent = DB8.getDb(testDb8Model.kind);
        for( var i=0; i<dbContent.length; ++i ) {
            var elt = dbContent[i];

            // Legacy behaviour: a where clause naming a plain array property
            // matched when one of its entries had that _id.
            if( testDb8Model.query.where && testDb8Model.query.where.length === 1 &&
                Array.isArray(elt[testDb8Model.query.where[0].prop]) ) {
                var list = elt[testDb8Model.query.where[0].prop];
                var wanted = testDb8Model.query.where[0].val;
                for( var j=0; j<list.length; ++j ) {
                    if( list[j] === wanted || (list[j] && list[j]._id === wanted) ) {
                        result.push(elt);
                        break;
                    }
                }
                continue;
            }

            if( DB8.matchesWhere(elt, testDb8Model.query.where) ) {
                result.push(elt);
            }
        }

        if( orderByProp !== undefined && orderByProp !== "" ) {
            result.sort(function(elt1,elt2) {
                var a = elt1[orderByProp];
                var b = elt2[orderByProp];
                // sortKey is a string; timestamps are numbers.
                var order = (typeof a === 'string' || typeof b === 'string')
                                ? String(a).localeCompare(String(b))
                                : (a - b);
                return ascending ? order : -order;
            });
        }

        testDb8Model.clear();
        var rows = DB8.unifyFields(result);
        testDb8Model._rows = rows;
        for( var sortedElt in rows ) {
            testDb8Model.append(rows[sortedElt]);
        }
        testDb8Model.status = "ready";
    }
}
