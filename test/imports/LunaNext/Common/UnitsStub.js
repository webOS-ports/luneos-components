/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
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

Qt.include("SettingsStub.js")

// Utility to convert a pixel length expressed at DPI=132 to
// a pixel length expressed in our DPI
function length(lengthAt132DPI) {
    return (lengthAt132DPI * layoutScale);
}

var DEFAULT_GRID_UNIT_PX = 8;

/*
 * What the real Units multiplies the grid unit by, from
 * /var/luna/preferences/ui-scale. Normal here: a desktop has no such file and
 * the real thing falls back to 1.0 the same way. It is a value and not a
 * function because the real one is a CONSTANT property - the scale is fixed
 * for the life of a process, which is the whole reason the Accessibility
 * panel has to say a change takes effect next time.
 */
var uiScale = 1.0;

function dp(value) {
    var ratio = gridUnit / DEFAULT_GRID_UNIT_PX;
    if (value <= 2.0)
        // for values under 2dp, return only multiples of the value
        return Math.round(value * Math.floor(ratio));
    return Math.round(value * ratio);
}

function gu(value) {
    return Math.round(value * gridUnit);
}
