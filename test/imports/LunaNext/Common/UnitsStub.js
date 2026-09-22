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
 * uiScale comes from SettingsStub, which parses it off the command line at
 * load. It is deliberately not settable from here: every library that
 * Qt.include()s another gets its own copy of its variables, so a setter here
 * would move Units and leave FontUtils - which reads the scale through its
 * own include of this file - at 1.0. Text would then not grow with the rest,
 * which is precisely the bug this replaced.
 *
 * Pass --ui-scale=<n> to the run instead, the same way --profile picks the
 * device. On a device the real Units reads the value once when it is
 * constructed, so it is fixed for the life of a process there too.
 */
function dp(value) {
    var ratio = (gridUnit * uiScale) / DEFAULT_GRID_UNIT_PX;
    if (value <= 2.0)
        // for values under 2dp, return only multiples of the value
        return Math.round(value * Math.floor(ratio));
    return Math.round(value * ratio);
}

function gu(value) {
    return Math.round(value * gridUnit * uiScale);
}
