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

    function syncDb8Model() {
        // Parse _internalDb and try to apply the query
        // We make the assumption that the query is a simple classic one

        var propFilter = "";
        var propFilterValue = "";
        if( testDb8Model.query.where ) {
            propFilter = testDb8Model.query.where[0].prop;
            propFilterValue = testDb8Model.query.where[0].val;
        }
        var orderByProp = testDb8Model.query.orderBy;
        var ascending = !testDb8Model.query.desc;

        var result = [];

        var dbContent = DB8.getDb(testDb8Model.kind);
        for( var i=0; i<dbContent.length; ++i ) {
            var elt = dbContent[i];
            if( !testDb8Model.query.where ) {
                // no filtering --> go on
                result.push(elt);
            }
            else {
                // apply filter. Only "prop" and "=" are supported so far.
                if (typeof elt[propFilter] === 'object') {
                    for( var j=0; j<elt[propFilter].length; ++j) {
                        var subElt = elt[propFilter][j];
                        if (subElt._id === propFilterValue) {
                            result.push(elt);
                            break;
                        }
                    }
                }
                else if (elt[propFilter] === propFilterValue) {
                    result.push(elt);
                }
            }
        }

        if( orderByProp !== "" ) {
            result.sort(function(elt1,elt2) {
                if( ascending ) {
                    return elt1[orderByProp] - elt2[orderByProp];
                }
                else {
                    return elt2[orderByProp] - elt1[orderByProp];
                }
            });
        }

        testDb8Model.clear();
        for( var sortedElt in result ) {
            testDb8Model.append(result[sortedElt]);
        }
    }
}
