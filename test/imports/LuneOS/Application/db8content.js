/*
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


.pragma library

var _internalDb8 = {};
var testDataFileParsed = [];

function generateId()
{
    // low risk of collision up to 10k numbers
    return '++QML' + Math.random().toString(36).substr(2, 9);
}

function initDb8Kind(kind, syncDb8Model)
{
    if( !_internalDb8[kind] ) _internalDb8[kind] = { "syncFct": [], "data": [] };
    _internalDb8[kind].syncFct.push(syncDb8Model);
}

function unregisterListener(kind, syncDb8Model)
{
    if( !_internalDb8[kind] ) return;
    var idxFct = _internalDb8[kind].syncFct.indexOf(syncDb8Model);
    _internalDb8[kind].syncFct.splice(idxFct,1);
}

function put(kind, dataArray)
{
    for(var dataObj in dataArray) {
        var data = dataArray[dataObj];
        if( !data._kind ) data._kind = kind
        if( !data._id ) data._id = generateId();
        _internalDb8[kind].data.push(data);
    }
    _internalDb8[kind].syncFct.forEach(function(fct) { fct() });
}

function getDb(kind)
{
    return _internalDb8[kind].data;
}
