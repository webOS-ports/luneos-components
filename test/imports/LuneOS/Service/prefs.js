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
 * A stand-in for luna-sysservice's preference store.
 *
 * The mock used to answer getPreferences from a handful of hard-coded replies
 * keyed on the exact set of keys asked for, and threw away everything
 * setPreferences was given. That is enough for an app that reads one or two
 * settings, but a settings app is nothing but preferences: a switch that
 * sprang back the moment it was flipped made the pages impossible to try on a
 * desktop.
 *
 * This keeps them instead, in memory for the length of the run, and tells
 * every subscriber what changed - which is what the real service does, and
 * what the pages are written against.
 *
 * The values below are the defaults a freshly flashed device would have.
 */
var values = {
    "timeFormat": "HH24",
    "useNetworkTime": true,
    "useNetworkTimeZone": true,
    "receiveNetworkTimeUpdate": true,
    "receiveNetworkTimezoneUpdate": true,
    "timeZone": {
        "City": "Amsterdam", "Description": "Central European Time",
        "CountryCode": "NL", "Country": "Netherlands", "supportsDST": 1,
        "ZoneID": "Europe/Amsterdam", "offsetFromUTC": 60, "preferred": true
    },

    "locale": {
        "languageCode": "en", "countryCode": "us",
        "phoneRegion": { "countryName": "United States", "countryCode": "us" }
    },
    "region": { "countryName": "Netherlands", "countryCode": "NL" },

    "keyboard": {
        "activeLanguage": "en",
        "enabledLanguages": ["en"],
        "autoCapitalization": true,
        "autoCorrection": true,
        "predictiveText": true,
        "spellChecking": true,
        "keyPressFeedback": true,
        "keyboardSize": "M",
        "keyboardLayout": "LuneOS"
    },

    "wallpaper": {
        "wallpaperName": "background.jpg",
        "wallpaperFile": "images/background.jpg",
        "wallpaperThumbFile": "images/background.jpg"
    },

    "muteSound": false,
    "systemSounds": true,
    "VibrateWhenRingerOn": true,
    "VibrateWhenRingerOff": true,
    // Left unset on purpose, as the mock always has: an app that is meant
    // to ask the user which ringtone to use only shows its chooser while
    // there is none.
    "ringtone": { "fullPath": "", "name": "" },
    "alerttone": { "fullPath": "/usr/palm/sounds/alert.wav", "name": "alert.wav" },
    "notificationtone": { "fullPath": "/usr/palm/sounds/notification.wav",
                          "name": "notification.wav" },

    "enableALS": true,
    "sysUiEnableNextPrevGestures": true,
    "showAlertsWhenLocked": true,
    "BlinkNotifications": false,
    "lockTimeout": 0,
    "enableFingerprintUnlock": true,

    "airplaneMode": false,
    "rotationLock": false,
    "4DigitNumber": "+312055512"
};

/*
 * Subscribers, as { keys: [...], callback: fct }. A subscriber only hears
 * about the keys it asked for, the way the real service reports.
 */
var subscribers = [];

function subscribe(keys, callback)
{
    subscribers.push({ "keys": keys || [], "callback": callback });
}

function has(key)
{
    return values.hasOwnProperty(key);
}

/**
 * The requested keys and their values, plus returnValue. Keys that are not
 * set are left out, exactly as the service leaves them out.
 */
function read(keys, subscribed)
{
    var message = { "returnValue": true };
    if( subscribed ) message.subscribed = true;

    var wanted = keys && keys.length ? keys : Object.keys(values);
    for( var i = 0; i < wanted.length; ++i ) {
        if( values.hasOwnProperty(wanted[i]) )
            message[wanted[i]] = values[wanted[i]];
    }

    return message;
}

/**
 * Stores what was written and reports it on. Returns the keys that changed.
 */
function write(newValues)
{
    var changed = [];

    for( var key in newValues ) {
        if( key === "subscribe" ) continue;
        values[key] = newValues[key];
        changed.push(key);
    }

    _notify(changed);
    return changed;
}

function _notify(changed)
{
    subscribers.forEach(function(subscriber) {
        var relevant = subscriber.keys.filter(function(key) {
            return changed.indexOf(key) >= 0;
        });
        if( relevant.length === 0 ) return;

        subscriber.callback({ "payload": JSON.stringify(read(relevant, true)) });
    });
}
