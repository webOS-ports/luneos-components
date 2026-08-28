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

    onQueryChanged: {
        syncDb8Model();
    }

    Component.onCompleted: DB8.initDb8Kind(kind, syncDb8Model);
    Component.onDestruction: DB8.unregisterListener(kind, syncDb8Model);

    function put(dataArray)
    {
        DB8.put(testDb8Model.kind, dataArray);
    }

    function putOnKind(forcedKind, dataArray)
    {
        DB8.put(forcedKind, dataArray);
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

    function del(ids)
    {
        DB8.del(testDb8Model.kind, ids, undefined);
    }

    function merge(dataArray)
    {
        DB8.merge(testDb8Model.kind, dataArray);
    }

    function syncDb8Model() {
        // Parse _internalDb and try to apply the query.
        // Filtering understands every clause in the where array, dotted
        // property paths ("capabilityProviders.capability") and arrays along
        // the way, which is what the accounts and contacts queries need.

        if( !testDb8Model.query ) return;

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
        for( var sortedElt in rows ) {
            testDb8Model.append(rows[sortedElt]);
        }
    }
}
