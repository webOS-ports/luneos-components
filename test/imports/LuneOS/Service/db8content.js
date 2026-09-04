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
var _seededKinds = {};

function generateId()
{
    // low risk of collision up to 10k numbers
    return '++QML' + Math.random().toString(36).substr(2, 9);
}

/*
 * Seeds a kind with example rows exactly once, ever - unlike the hard-coded
 * canned responses findDb_call answers com.palm.browserhistory:1 and
 * friends with, this goes through the same mutable in-memory store put/del
 * everyone else uses, so deleting a seeded row (testing a swipe-to-delete,
 * say) actually removes it rather than having it reappear the next time the
 * owning page re-opens and asks to be seeded again.
 */
function seedOnce(kind, rows)
{
    if( _seededKinds[kind] ) return;
    _seededKinds[kind] = true;

    initDb8Kind(kind, function() {});
    put(kind, rows);
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

// Every kind something has been stored under, for a caller that has an id but
// not the kind it belongs to.
function kinds()
{
    return Object.keys(_internalDb8);
}

function getDb(kind)
{
    if( typeof _internalDb8[kind] === 'undefined' ) return []
    return _internalDb8[kind].data;
}

function _notify(kind)
{
    if( !_internalDb8[kind] ) return;
    _internalDb8[kind].syncFct.forEach(function(fct) { fct() });
}

// Applies changes to existing records, matched on _id. Used by anything that
// goes through luna://com.palm.db/merge.
function merge(kind, dataArray)
{
    if( !_internalDb8[kind] ) return 0;

    var data = _internalDb8[kind].data;
    var count = 0;

    dataArray.forEach(function(changes) {
        for( var i=0; i<data.length; ++i ) {
            if( data[i]._id !== changes._id ) continue;

            for( var key in changes ) data[i][key] = changes[key];
            count++;
            break;
        }
    });

    _notify(kind);
    return count;
}

// Removes records by _id, or every record matching a where clause. Used by
// luna://com.palm.db/del, which the call log needs to delete a group.
function del(kind, ids, where)
{
    if( !_internalDb8[kind] ) return 0;

    var data = _internalDb8[kind].data;
    var before = data.length;

    _internalDb8[kind].data = data.filter(function(elt) {
        if( ids && ids.indexOf(elt._id) >= 0 ) return false;
        if( where && matchesWhere(elt, where) ) return false;
        return true;
    });

    _notify(kind);
    return before - _internalDb8[kind].data.length;
}

// Reads a possibly dotted property path off a record, so a query on
// "capabilityProviders.capability" finds the value inside the nested objects
// the way db8 does.
function valueAt(elt, path)
{
    var parts = String(path).split(".");
    var current = elt;

    for( var i=0; i<parts.length; ++i ) {
        if( current === undefined || current === null ) return undefined;

        // A path segment may cross an array: gather the matches from each entry.
        if( Array.isArray(current) ) {
            var collected = [];
            current.forEach(function(entry) {
                var value = valueAt(entry, parts.slice(i).join("."));
                if( value === undefined ) return;
                if( Array.isArray(value) ) collected = collected.concat(value);
                else collected.push(value);
            });
            return collected;
        }

        current = current[parts[i]];
    }

    return current;
}

// Evaluates a db8 where clause against one record. Supports '=' and the '%'
// prefix operator, over dotted paths and arrays.
/**
 * A value of the same shape as `sample` but carrying nothing: 0, "", false, an
 * empty list, or an object whose own fields are likewise emptied.
 */
function emptyLike(sample)
{
    if( Array.isArray(sample) )
        return [];

    switch( typeof sample ) {
    case 'number':  return 0;
    case 'boolean': return false;
    case 'string':  return "";
    case 'object':
        if( sample === null )
            return "";
        var blank = {};
        for( var key in sample )
            blank[key] = emptyLike(sample[key]);
        return blank;
    }

    return "";
}

/**
 * Gives every record the union of the fields found across all of them.
 *
 * A ListModel takes its roles from the first row it is given, so a field that
 * happens to be missing there -- an optional one like a call's duration -- would
 * be unreadable on every other row too. db8 itself has no such limitation, so
 * filling the gaps here keeps the mock honest.
 */
function unifyFields(records)
{
    var samples = {};
    var i, key;

    for( i = 0; i < records.length; ++i )
        for( key in records[i] )
            if( !(key in samples) && records[i][key] !== undefined )
                samples[key] = records[i][key];

    var unified = [];
    for( i = 0; i < records.length; ++i ) {
        var row = {};
        for( key in samples )
            row[key] = (records[i][key] !== undefined) ? records[i][key]
                                                       : emptyLike(samples[key]);
        unified.push(row);
    }

    return unified;
}

function matchesWhere(elt, where)
{
    if( !where ) return true;

    for( var i=0; i<where.length; ++i ) {
        var clause = where[i];
        var value = valueAt(elt, clause.prop);
        var candidates = Array.isArray(value) ? value : [ value ];

        var matched = candidates.some(function(candidate) {
            if( candidate === undefined || candidate === null ) return false;

            switch( clause.op ) {
            case "%":
                return String(candidate).indexOf(String(clause.val)) === 0;
            case "!=":
                return candidate !== clause.val;
            case "=":
            default:
                return candidate === clause.val;
            }
        });

        if( !matched ) return false;
    }

    return true;
}
