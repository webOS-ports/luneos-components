/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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

/*
 * A stand-in for org.webosports.service.tweaks.prefs.
 *
 * The mock used to answer /get from a chain of `args.keys == "oneKey"`
 * comparisons, which only worked at all because a one-element array compares
 * equal to its own contents. A caller asking for several keys in one call -
 * which is what the real service's "keys" array is for, and what a page
 * showing a group of tweaks does - fell past every branch and was handed an
 * undefined payload to parse.
 *
 * A table answers any subset, one key or ten, and /set writes back into it so
 * a tweak flipped on a desktop stays flipped.
 *
 * The values are luna-next-cardshell's own declared defaults, from its
 * preference definition file.
 */
var values = {
    "dialPadFeedback": "vibrateOnly",
    "alwaysShowProgressBarKey": true,
    "privateByDefaultKey": true,
    "toggleVKBKey": true,
    "tapRippleSupport": true,
    "showGestureArea": true,
    "tabTitleCase": "capitalizedCase",
    "tabIndicatorNumber": "default",
    "stackedCardSupport": true,
    "infiniteCardCycling": true,
    "showDebugDotGrid": false,
    "showDateTime": "timeOnly",
    "showBatteryPercentage": "iconOnly",
    "batteryPercentageColor": "white",
    "useCustomCarrierString": false,
    "carrierString": "LuneOS",
    "useNewDeviceMenu": false
};

function getPayload(keys) {
    var message = { "returnValue": true };

    if (keys === undefined)
        keys = [];
    else if (!Array.isArray(keys))
        keys = [keys];

    for (var i = 0; i < keys.length; i++) {
        if (values.hasOwnProperty(keys[i]))
            message[keys[i]] = values[keys[i]];
        else
            console.log("No tweak in the mock for: " + keys[i]);
    }

    return message;
}

/* Everything but "owner" is a key to write, which is how the real set
 * assistant reads its arguments too. */
function set(args) {
    for (var key in args) {
        if (key !== "owner")
            values[key] = args[key];
    }

    return { "returnValue": true };
}
