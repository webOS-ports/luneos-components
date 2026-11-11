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
    // The locked angle in degrees, or 400 when the screen turns freely, as
    // the shell writes it. luna-sysservice ships no default; every reader
    // (the shell, Settings, the camera, LuneOS.System's DeviceOrientation)
    // takes it as a number, and a false here read as locked at 0.
    "rotationLock": 400,
    "4DigitNumber": "+312055512",

    // LocationPage.qml's global prefs - com.palm.location (the real legacy
    // service these belonged to, per luneos-vpn-adapter-style research into
    // the shipped TouchPad rootfs) does not exist on LuneOS, so these are
    // ordinary preferences instead of a dedicated service's, same as
    // TextAssistPage's keyboard settings.
    "autoLocate": true,
    "webSetting": true,
    "geotagPhotos": false
};

/*
 * Subscribers, as { keys: [...], callback: fct }. A subscriber only hears
 * about the keys it asked for, the way the real service reports.
 *
 * subscribe() returns the function that ends the subscription: the real
 * service stops answering a call once it is cancelled, and a call is
 * cancelled when the LunaService that made it is destroyed.
 */
var subscribers = [];

function subscribe(keys, callback)
{
    var subscriber = { "keys": keys || [], "callback": callback };
    subscribers.push(subscriber);
    return function() {
        var i = subscribers.indexOf(subscriber);
        if( i >= 0 ) subscribers.splice(i, 1);
    };
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
    // A copy: a callback may end a subscription, its own or another's.
    subscribers.slice().forEach(function(subscriber) {
        if( subscribers.indexOf(subscriber) < 0 ) return;
        var relevant = subscriber.keys.filter(function(key) {
            return changed.indexOf(key) >= 0;
        });
        if( relevant.length === 0 ) return;

        subscriber.callback({ "payload": JSON.stringify(read(relevant, true)) });
    });
}
