/*
 * Copyright (C) 2013-2017 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2015-2017 Herman van Hazendonk <github.com@herrie.org>
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

import QtQuick 2.0

import "LunaServiceRegistering.js" as LSRegisteredMethods

QtObject {
    property string name
    property string method
    property bool usePrivateBus: false
    property string service

    property var lockStatusSubscriber
    property string currentLockStatus: "locked"
    property string currentSimState: "pinrequired"

    property var deviceLockModeSubscriber
    property string deviceLockMode: "none"
    property string polcyState: "none"
    property int retriesLeft: 3
    property string configuredPasscode: "4242"

    signal response
    signal initialized
    property var onResponse
    property var onError

    Component.onCompleted: {
        initialized();

        LSRegisteredMethods.executeMethod("luna://com.palm.applicationManager/launchPointChanges", {"applicationId": name, "payload": "{}"});
    }

    function call(serviceURI, jsonArgs, returnFct, handleError) {
        if(arguments.length === 1) {
            // handle the short form of call
            return call(service+"/"+method, arguments[0], onResponse, onError);
        }
        else if(arguments.length === 3) {
            // handle the intermediate form of call
            return call(service+"/"+method, arguments[0], arguments[1], arguments[2]);
        }

        console.log("LunaService::call called with serviceURI=" + serviceURI + ", args=" + jsonArgs);

        var args = JSON.parse(jsonArgs) ;
        if(serviceURI === "luna://com.palm.applicationManager/listLaunchPoints") {
            listLaunchPoints_call(args, returnFct, handleError);
        }
        else if(serviceURI === "palm://com.palm.appinstaller/remove" || serviceURI === "luna://com.palm.appinstaller/remove") {
            removeApp_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.applicationManager/launch" ) {
            launchApp_call(args, returnFct, handleError);
        }
        else if(serviceURI === "palm://com.palm.applicationManager/getAppInfo" || serviceURI === "luna://com.palm.applicationManager/getAppInfo") {
            giveFakeAppInfo_call(args, returnFct, handleError);
        }
        else if(serviceURI === "palm://com.palm.applicationManager/getAppBasePath" || serviceURI === "luna://com.palm.applicationManager/getAppBasePath") {
            giveFakeAppBasePath_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.display/control/setLockStatus") {
            setLockStatus_call(args, returnFct, handleError);
        }
        else if(serviceURI === "palm://com.palm.display/control/getProperty" || serviceURI === "luna://com.palm.display/control/getProperty") {
            getDisplayProperty_call(args, returnFct, handleError);
        }
        else if(serviceURI === "palm://com.palm.display/control/alert" || serviceURI === "luna://com.palm.display/control/alert") {
            displayAlert_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.systemmanager/getDeviceLockMode") {
            getDeviceLockMode_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.systemservice/getPreferences") {
            getPreferences_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.systemservice/deviceInfo/query") {
            deviceInfoQuery_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.systemservice/setPreferences") {
            setPreferences_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.wifi/connect") {
            wifiConnect_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.wifi/setstate") {
            wifiSetState_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.wan/set") {
            wanSet_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.systemservice/getPreferenceValues") {
            getPreferenceValues_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.systemmanager/matchDevicePasscode") {
            matchDevicePasscode_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.power/com/palm/power/batteryStatusQuery") {
            getBatteryStatusQuery_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.power/com/palm/power/chargerStatusQuery") {
            getChargerStatusQuery_call(args, returnFct, handleError);
        }
        else if(serviceURI ==="luna://com.palm.connectionmanager/getstatus") {
            getConnectionManagerStatus_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.connectionmanager/getinfo") {
            getConnectionManagerInfo_call(args, returnFct, handleError);
        }
        else if(serviceURI ==="luna://com.palm.db/find") {
            findDb_call(args, returnFct, handleError);
        }
        else if(serviceURI ==="luna://com.palm.db/merge") {
            mergeDb_call(args, returnFct, handleError);
        }
        else if(serviceURI ==="luna://com.palm.db/search") {
            findDb_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://org.webosinternals.ipkgservice/getConfigs") {
            getConfigs_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://org.webosinternals.ipkgservice/setConfigState") {
            setConfigState_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://org.webosinternals.tweaks.prefs/get") {
            getTweaks_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.universalsearch/getUniversalSearchList") {
            getUniversalSearch_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://org.webosports.service.update/retrieveVersion") {
            retrieveVersion_call(args, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.android.properties/getProperty") {
            androidGetProperty_call(args, returnFct, handleError);
        }
        else {
            // Embed the jsonArgs into a payload message
            var message = { applicationId: "org.webosports.tests.dummyWindow", payload: jsonArgs };
            if(!(LSRegisteredMethods.executeMethod(serviceURI, message))) {
                if (handleError)
                    handleError("unrecognized call: " + serviceURI);
            }
        }
    }

    function subscribe(serviceURI, jsonArgs, returnFct, handleError) {
        if(arguments.length === 1) {
            // handle the short form of subscribe
            return subscribe(service+"/"+method, arguments[0], onResponse, onError);
        }
        else if(arguments.length === 3) {
            // handle the intermediate form of subscribe
            return subscribe(service+"/"+method, arguments[0], arguments[1], arguments[2]);
        }

        var args = JSON.parse(jsonArgs);
        if(serviceURI === "palm://com.palm.bus/signal/registerServerStatus" || serviceURI === "luna://com.palm.bus/signal/registerServerStatus") {
            if(typeof returnFct !== 'undefined') {
                returnFct({"payload": JSON.stringify({"connected": true})});
            }
        }
        else if(serviceURI === "luna://com.palm.applicationManager/launchPointChanges" && args.subscribe) {
            returnFct({"payload": JSON.stringify({"subscribed": true})}); // simulate subscription answer
            LSRegisteredMethods.addRegisteredMethod("luna://com.palm.applicationManager/launchPointChanges", returnFct);
            //returnFct({"payload": JSON.stringify({})});
        }
        else if(serviceURI === "luna://org.webosports.bootmgr/getStatus" && args.subscribe) {
            console.log("bootmgr status: normal");
            returnFct({"payload": JSON.stringify({"subscribed":true, "state": "normal"})}); // simulate subscription answer
        }
        else if((serviceURI === "palm://com.palm.systemservice/getPreferences" ||
                 serviceURI === "luna://com.palm.systemservice/getPreferences" ||
                 serviceURI === "luna://com.webos.service.systemservice/getPreferences" )
                && args.subscribe) {
            returnFct({"payload": JSON.stringify({"subscribed": true, "wallpaper": { "wallpaperFile": "images/background.jpg"}, "timeFormat":"HH24", "locale": { "languageCode": "en", "countryCode": "us", "phoneRegion": { "countryName": "United States", "countryCode": "us" } }})});
        }
        else if(serviceURI === "luna://org.webosports.audio/getStatus") {
            returnFct({"payload": JSON.stringify({"volume":54,"mute":false})});
        }
        else if(serviceURI === "luna://com.palm.display/control/lockStatus") {
            lockStatusSubscriber =  {func: returnFct};
            returnFct({payload: "{\"lockState\":\"" + currentLockStatus + "\"}"});
        }
        else if(serviceURI === "luna://com.palm.systemmanager/getDeviceLockMode") {
            deviceLockModeSubscriber = {func: returnFct};
            getDeviceLockMode_call(jsonArgs, returnFct, handleError);
        }
        else if(serviceURI === "luna://com.palm.telephony/simStatusQuery") {
            var simState = {
                "subscribed": true,
                "returnValue":true,
                "extended": { "state": "pinrequired" }
            };
            var respData = {"payload": JSON.stringify(simState)};
            returnFct(respData);
        }
        else if(serviceURI === "palm://com.palm.bus/signal/addmatch" || serviceURI === "luna://com.palm.bus/signal/addmatch") {
            LSRegisteredMethods.addRegisteredMethod("luna://" + name + args.category + "/" + args.name, returnFct);
            returnFct({"payload": JSON.stringify({"subscribed": true, "Charging": false, "percent_ui": 10})}); // simulate subscription answer
        }
        else if(serviceURI === "luna://com.palm.wifi/findnetworks") {
            //return WiFi networks
            var message = {"returnValue":true, "foundNetworks":[{"networkInfo":{"signalLevel":25,"profileId":777,"ssid":"Test WiFi 1 Bar Security: psk","signalBars":1,"supported":true,"availableSecurityTypes":["psk"],"connectState":"ipConfigured"}},{"networkInfo":{"signalLevel":50,"ssid":"Test WiFi 2 Bars Security: wps","signalBars":2,"supported":true,"availableSecurityTypes":["wps"]}},{"networkInfo":{"signalLevel":75,"ssid":"Test WiFi 3 Bars Security: wep","signalBars":3,"supported":true,"availableSecurityTypes":["wep"]}},{"networkInfo":{"signalLevel":75,"ssid":"Test WiFi 3 Bars Security: ieee8021x","signalBars":3,"supported":true,"availableSecurityTypes":["ieee8021x"]}},{"networkInfo":{"signalLevel":75,"ssid":"Test WiFi 3 Bars Security: none","signalBars":3,"supported":true,"availableSecurityTypes":[]}}]};
            returnFct({payload: JSON.stringify(message)});
        }
    }

    function registerMethod(category, fct, callback) {
        console.log("registering " + "luna://" + name + category + fct);
        LSRegisteredMethods.addRegisteredMethod("luna://" + name + category + fct, callback);
    }

    function addSubscription() {
        /* do nothing */
    }

    function replyToSubscribers(path, callerAppId, jsonArgs) {
        console.log("replyToSubscribers " + "luna://" + name + path);
        LSRegisteredMethods.executeMethod("luna://" + name + path, {"applicationId": callerAppId, "payload": jsonArgs});
    }

    function listLaunchPoints_call(jsonArgs, returnFct, handleError) {
        returnFct({"payload": JSON.stringify({"returnValue": true,
                   "launchPoints": LSRegisteredMethods._listLaunchPoints})});
    }

    function removeApp_call(jsonArgs, returnFct, handleError) {
        var newListLaunchPoints = [];
        var appHasBeenRemoved = false;

        for( var i = 0; i < LSRegisteredMethods._listLaunchPoints.length; ++i ) {
            if( LSRegisteredMethods._listLaunchPoints[i].id !== jsonArgs.packageName ) {
                newListLaunchPoints.push(LSRegisteredMethods._listLaunchPoints[i]);
            }
            else {
                appHasBeenRemoved = true;
                console.log("removed " + LSRegisteredMethods._listLaunchPoints[i].id + " from the list of launchPoints");
            }
        }

        if( appHasBeenRemoved ) {
            LSRegisteredMethods._listLaunchPoints = newListLaunchPoints;
            LSRegisteredMethods.executeMethod("luna://com.palm.applicationManager/launchPointChanges", {"applicationId": name, "payload": "{}"});
        }
    }

    function giveFakeAppInfo_call(args, returnFct, handleError) {
        returnFct({"payload": JSON.stringify({"returnValue": true, "appInfo": { "appmenu": "Fake App" } })});
    }

    function giveFakeAppBasePath_call(args, returnFct, handleError) {
        returnFct({"payload": JSON.stringify({ "returnValue": true, "appId": "org.webosports.tests.fakeDashboardWindow", "basePath": "" })});
    }

    function getDisplayProperty_call(args, returnFct, handleError) {
        returnFct({"payload": JSON.stringify({"returnValue": true, "maximumBrightness": 70 })});
    }

    function launchApp_call(jsonArgs, returnFct, handleError) {
        // The JSON params can contain "id" (string) and "params" (object)
        if(jsonArgs.id === "org.webosports.tests.dummyWindow" || jsonArgs.id === "org.webosports.tests.dummyWindow2") {
            // start a DummyWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("DummyWindow", jsonArgs);
        }
        else if(jsonArgs.id === "org.webosports.tests.fakeOverlayWindow") {
            // start a FakeOverlayWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("FakeOverlayWindow", jsonArgs);
        }
        else if(jsonArgs.id === "org.webosports.tests.fakeDashboardWindow") {
            // start a FakeDashboardWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("FakeDashboardWindow", jsonArgs);
        }
        else if(jsonArgs.id === "org.webosports.tests.fakePopupAlertWindow") {
            // start a FakePopupAlertWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("FakePopupAlertWindow", jsonArgs);
        }
        else if(jsonArgs.id === "org.webosports.tests.fakeSimPinWindow") {
            // start a FakeSIMPinWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("FakeSIMPinWindow", jsonArgs);
        }
        else if(jsonArgs.id === "org.webosports.tests.fakePopupWindow") {
            // start a FakePopupWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("FakePopupWindow", jsonArgs);
        }
        else {
            handleError("Error: parameter 'id' not specified");
        }
    }

    function createNotification_call(jsonArgs, returnFct, handleError) {
        if(jsonArgs) {
            var callerAppId = "org.webosports.tests.dummyWindow"; // hard-coded
            
        replyToSubscribers("/createNotification", callerAppId, jsonArgs);
        }
        else {
            handleError("Error: parameter 'id' not specified");
        }
    }

    function setLockStatus_call(args, returnFct, handleError) {
        console.log("setLockStatus_call: arg.status = " + args.status + " currentLockStatus = " + currentLockStatus);
        if (args.status === "unlock" && currentLockStatus === "locked") {
            currentLockStatus = "unlocked";
            lockStatusSubscriber.func({payload: "{\"lockState\":\"" + currentLockStatus + "\"}"});
        }
    }

    function displayAlert_call(args, returnFct, handleError) {
        console.log("displayAlert_call: args = " + JSON.stringify(args));
    }

    function getDeviceLockMode_call(args, returnFct, handleError) {
        var message = {
            "returnValue": true,
            "lockMode": deviceLockMode,
            "policyState": polcyState,
            "retriesLeft": retriesLeft
        };
        returnFct({payload: JSON.stringify(message)});
    }

    function getPreferences_call(args, returnFct, handleError) {

        //return preference value for locale
        if (args.keys == "locale") {
            var message = {
                "returnValue": true,
                "locale": { "languageCode": "en", "countryCode": "us", "phoneRegion": { "countryName": "United States", "countryCode": "us" } }
            };
        }
        else if(args.keys == "region,timeZone") {
            console.log("returning dummy region, timeZone")
            var message = {
                "returnValue": true,
                "region": { "countryName": "United States", "countryCode": "us" },
                "timeZone": { "City": "New York", "Description": "Eastern Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 1, "ZoneID": "America\/New_York", "offsetFromUTC": -300, "preferred": true }
            };
        }
        else if(args.keys == "region,timeZone,timeFormat,locale") {
            console.log("returning dummy region, timezone, timeFormat, locale")
            var message = {
                "returnValue": true,
                "timeFormat": "HH12",
                "region": { "countryName": "United States", "countryCode": "us" },
                "timeZone": { "City": "New York", "Description": "Eastern Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 1, "ZoneID": "America\/New_York", "offsetFromUTC": -300, "preferred": true },
                "locale": { "languageCode": "en", "countryCode": "us", "phoneRegion": { "countryName": "United States", "countryCode": "us" } }
            };
        }
        else if(args.keys == "region") {
            console.log("returning dummy region")
            var message = {
                "returnValue": true,
                "region": { "countryName": "United States", "countryCode": "us" }
            };
        }
        else if(args.keys == "ringtone","alerttone","notificationtone","locale") {
            var message = {
            "alerttone": { "fullPath": "\/usr\/palm\/sounds\/alert.wav", "name": "alert.wav" },
            "locale": { "languageCode": "en", "countryCode": "us", "phoneRegion": { "countryName": "United States", "countryCode": "us" } },
            "notificationtone": { "fullPath": "\/usr\/palm\/sounds\/notification.wav", "name": "notification.wav" },
            "ringtone": { "fullPath": "\/usr\/palm\/sounds\/ringtone.mp3", "name": "ringtone.mp3" },
            "subscribed": true,
            "returnValue": true
            };
        }
        else {
            console.log("We don't have a preferences for: "+args.keys);
        }
        returnFct({payload: JSON.stringify(message)});
    }

    function deviceInfoQuery_call(args, returnFct, handleError) {

        //returns device info
        var message = { 
            "battery_challenge": "not supported", 
            "battery_response": "not supported", 
            "board_type": "not supported", 
            "bt_addr": "not supported", 
            "device_name": "qemux86", 
            "hardware_id": "not supported", 
            "hardware_revision": "not supported", 
            "installer": "not supported", 
            "keyboard_type": "not supported", 
            "last_reset_type": "not supported", 
            "modem_present": "N", 
            "nduid": "d2adec88f1a4caa009b6db861578688b1474f0c9", 
            "product_id": "not supported", 
            "radio_type": "not supported", 
            "ram_size": "not supported", 
            "serial_number": "not supported", 
            "storage_free": "not supported", 
            "storage_size": "not supported", 
            "wifi_addr": "not supported", 
            "returnValue": true 
        };
        returnFct({payload: JSON.stringify(message)});
    }

    function setPreferences_call(args, returnFct, handleError) {
        var message = {"returnValue": true};
        returnFct({payload: JSON.stringify(message)});
    }

    function getPreferenceValues_call(args, returnFct, handleError) {
        //return preference values for locale
        var message = "";
        if (args.key == "locale") {
            message = { 
                "returnValue": true, "locale": [ { "languageName": "Albanian", "languageCode": "sq", "countries": [ { "countryName": "Albania", "countryCode": "al" }, { "countryName": "Montenegro", "countryCode": "me" } ] }, { "languageName": "Arabic", "languageCode": "ar", "countries": [ { "countryName": "Saudi Arabia", "countryCode": "sa" }, { "countryName": "Algeria", "countryCode": "dz" }, { "countryName": "Bahrain", "countryCode": "bh" }, { "countryName": "Djibouti", "countryCode": "dj" }, { "countryName": "Egypt", "countryCode": "eg" }, { "countryName": "Iraq", "countryCode": "iq" }, { "countryName": "Jordan", "countryCode": "jo" }, { "countryName": "Kuwait", "countryCode": "kw" }, { "countryName": "Lebanon", "countryCode": "lb" }, { "countryName": "Libya", "countryCode": "ly" }, { "countryName": "Mauritania", "countryCode": "mr" }, { "countryName": "Morocco", "countryCode": "ma" }, { "countryName": "Oman", "countryCode": "om" }, { "countryName": "Qatar", "countryCode": "qa" }, { "countryName": "Sudan", "countryCode": "sd" }, { "countryName": "Syria", "countryCode": "sy" }, { "countryName": "Tunisia", "countryCode": "tn" }, { "countryName": "UAE", "countryCode": "ae" }, { "countryName": "Yemen", "countryCode": "ye" } ] }, { "languageName": "Assamese", "languageCode": "as", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Bengali", "languageCode": "bn", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Bosnian", "languageCode": "bs", "countries": [ { "countryName": "Bosnia", "countryCode": "latn-ba" }, { "countryName": "Montenegro", "countryCode": "latn-me" } ] }, { "languageName": "Bulgarian", "languageCode": "bg", "countries": [ { "countryName": "Bulgaria", "countryCode": "bg" } ] }, { "languageName": "Croation", "languageCode": "hr", "countries": [ { "countryName": "Croatia", "countryCode": "hr" }, { "countryName": "Montenegro", "countryCode": "me" } ] }, { "languageName": "Czech", "languageCode": "cs", "countries": [ { "countryName": "Czech Republic", "countryCode": "cz" } ] }, { "languageName": "Deutsch", "languageCode": "de", "countries": [ { "countryName": "Deutschland", "countryCode": "de" }, { "countryName": "Austria", "countryCode": "at" }, { "countryName": "Swizerland", "countryCode": "ch" }, { "countryName": "Luxemburg", "countryCode": "lu" } ] }, { "languageName": "Danish", "languageCode": "da", "countries": [ { "countryName": "Denmark", "countryCode": "dk" } ] }, { "languageName": "Dutch", "languageCode": "nl", "countries": [ { "countryName": "Belgium", "countryCode": "be" }, { "countryName": "Netherlands", "countryCode": "nl" } ] }, { "languageName": "English", "languageCode": "en", "countries": [ { "countryName": "United States", "countryCode": "us" }, { "countryName": "United Kingdom", "countryCode": "gb" }, { "countryName": "Pseudoland", "countryCode": "pl" }, { "countryName": "Canada", "countryCode": "ca" }, { "countryName": "Ireland", "countryCode": "ie" }, { "countryName": "Mexico", "countryCode": "mx" }, { "countryName": "China", "countryCode": "cn" }, { "countryName": "Taiwan", "countryCode": "tw" }, { "countryName": "India", "countryCode": "in" }, { "countryName": "Australia", "countryCode": "au" }, { "countryName": "New Zealand", "countryCode": "nz" }, { "countryName": "South Africa", "countryCode": "za" }, { "countryName": "Azerbaijan", "countryCode": "az" }, { "countryName": "Armenia", "countryCode": "am" }, { "countryName": "Ethiopia", "countryCode": "et" }, { "countryName": "Gambia", "countryCode": "gm" }, { "countryName": "Ghana", "countryCode": "gh" }, { "countryName": "Hong Kong", "countryCode": "hk" }, { "countryName": "Iceland", "countryCode": "is" }, { "countryName": "Kenya", "countryCode": "ke" }, { "countryName": "Liberia", "countryCode": "lr" }, { "countryName": "Malawi", "countryCode": "mw" }, { "countryName": "Myanmar", "countryCode": "mm" }, { "countryName": "South Africa", "countryCode": "za" }, { "countryName": "Nigeria", "countryCode": "ng" }, { "countryName": "Pakistan", "countryCode": "pk" }, { "countryName": "Philippines", "countryCode": "ph" }, { "countryName": "Puerto Rico", "countryCode": "pr" }, { "countryName": "Rwanda", "countryCode": "rw" }, { "countryName": "Sierra Leone", "countryCode": "sl" }, { "countryName": "Singapore", "countryCode": "sg" }, { "countryName": "Sri Lanka", "countryCode": "lk" }, { "countryName": "Sudan", "countryCode": "sd" }, { "countryName": "Tanzania", "countryCode": "tz" }, { "countryName": "Uganda", "countryCode": "ug" }, { "countryName": "Malaysia", "countryCode": "my" }, { "countryName": "Mauritius", "countryCode": "mu" }, { "countryName": "Zambia", "countryCode": "zm" } ] }, { "languageName": "Español", "languageCode": "es", "countries": [ { "countryName": "Estados Unidos", "countryCode": "us" }, { "countryName": "España", "countryCode": "es" }, { "countryName": "México", "countryCode": "mx" }, { "countryName": "Colombia", "countryCode": "co" }, { "countryName": "Guinea Equatorial", "countryCode": "gq" }, { "countryName": "Argentina", "countryCode": "ar" }, { "countryName": "Bolivia", "countryCode": "bo" }, { "countryName": "Chile", "countryCode": "cl" }, { "countryName": "Costa Rica", "countryCode": "cr" }, { "countryName": "Dominican Republic", "countryCode": "do" }, { "countryName": "Ecuador", "countryCode": "ec" }, { "countryName": "El Salvador", "countryCode": "sv" }, { "countryName": "Guatemala", "countryCode": "gt" }, { "countryName": "Honduras", "countryCode": "hn" }, { "countryName": "Panama", "countryCode": "pa" }, { "countryName": "Nicaragua", "countryCode": "ni" }, { "countryName": "Paraguay", "countryCode": "py" }, { "countryName": "Peru", "countryCode": "pe" }, { "countryName": "Philippines", "countryCode": "ph" }, { "countryName": "Puerto Rico", "countryCode": "pr" }, { "countryName": "Uruguay", "countryCode": "uy" }, { "countryName": "Venezuela", "countryCode": "ve" } ] }, { "languageName": "Estonian", "languageCode": "et", "countries": [ { "countryName": "Estonia", "countryCode": "ee" } ] }, { "languageName": "Farsi", "languageCode": "fa", "countries": [ { "countryName": "Afghanistan", "countryCode": "af" }, { "countryName": "Iran", "countryCode": "ir" } ] }, { "languageName": "Finnish", "languageCode": "fi", "countries": [ { "countryName": "Finland", "countryCode": "fi" } ] }, { "languageName": "Français", "languageCode": "fr", "countries": [ { "countryName": "France", "countryCode": "fr" }, { "countryName": "Canada", "countryCode": "ca" }, { "countryName": "Algeria", "countryCode": "dz" }, { "countryName": "Belgium", "countryCode": "be" }, { "countryName": "Guinea Equatorial", "countryCode": "cq" }, { "countryName": "Swizerland", "countryCode": "ch" }, { "countryName": "Luxemburg", "countryCode": "lu" }, { "countryName": "Benin", "countryCode": "bj" }, { "countryName": "Burkina Faso", "countryCode": "bf" }, { "countryName": "Cameroon", "countryCode": "cm" }, { "countryName": "Central African Republic", "countryCode": "cf" }, { "countryName": "Democratic Republic Congo", "countryCode": "cd" }, { "countryName": "Djibouti", "countryCode": "dj" }, { "countryName": "Gabon", "countryCode": "ga" }, { "countryName": "Guinea", "countryCode": "gn" }, { "countryName": "Ivory Coast", "countryCode": "ci" }, { "countryName": "Lebanon", "countryCode": "lb" }, { "countryName": "Mali", "countryCode": "ml" }, { "countryName": "Republic of the Congo", "countryCode": "cg" }, { "countryName": "Rwanda", "countryCode": "rw" }, { "countryName": "Senegal", "countryCode": "sn" }, { "countryName": "Mauritius", "countryCode": "mu" }, { "countryName": "Togo", "countryCode": "tg" } ] }, { "languageName": "Gaelic", "languageCode": "ga", "countries": [ { "countryName": "Ireland", "countryCode": "ie" } ] }, { "languageName": "Greek", "languageCode": "el", "countries": [ { "countryName": "Greece", "countryCode": "gr" }, { "countryName": "Cyprus", "countryCode": "cy" } ] }, { "languageName": "Gujarathi", "languageCode": "gu", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Hebrew", "languageCode": "he", "countries": [ { "countryName": "Isreal", "countryCode": "il" } ] }, { "languageName": "Hindi", "languageCode": "hi", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Hungarian", "languageCode": "hu", "countries": [ { "countryName": "Hungary", "countryCode": "hu" } ] }, { "languageName": "Indonesian", "languageCode": "id", "countries": [ { "countryName": "Indonesia", "countryCode": "id" } ] }, { "languageName": "Italiano", "languageCode": "it", "countries": [ { "countryName": "Italia", "countryCode": "it" }, { "countryName": "Swizerland", "countryCode": "ch" } ] }, { "languageName": "Japanese", "languageCode": "ja", "countries": [ { "countryName": "Japan", "countryCode": "jp" } ] }, { "languageName": "Kannada", "languageCode": "kn", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Kazakh", "languageCode": "kk", "countries": [ { "countryName": "Kazakhstan", "countryCode": "cyrl-kz" } ] }, { "languageName": "Korean", "languageCode": "ko", "countries": [ { "countryName": "Korea, Republic of", "countryCode": "kr" }, { "countryName": "Japan", "countryCode": "jp" } ] }, { "languageName": "Kurdish", "languageCode": "ku", "countries": [ { "countryName": "Iraq", "countryCode": "arab-iq" } ] }, { "languageName": "Latvian", "languageCode": "lv", "countries": [ { "countryName": "Latvia", "countryCode": "lv" } ] }, { "languageName": "Lithunian", "languageCode": "lt", "countries": [ { "countryName": "Lithuania", "countryCode": "lt" } ] }, { "languageName": "Malayalam", "languageCode": "ml", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Macedonian", "languageCode": "mk", "countries": [ { "countryName": "Macedonia", "countryCode": "mk" } ] }, { "languageName": "Malaysian", "languageCode": "ms", "countries": [ { "countryName": "Malaysia", "countryCode": "my" }, { "countryName": "Singapore", "countryCode": "sg" } ] }, { "languageName": "Marathi", "languageCode": "mr", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Mongolian", "languageCode": "mn", "countries": [ { "countryName": "Mongolia", "countryCode": "cyrl-mn" } ] }, { "languageName": "Norwegia Bokmal", "languageCode": "nb", "countries": [ { "countryName": "Norway", "countryCode": "no" } ] }, { "languageName": "Polish", "languageCode": "pl", "countries": [ { "countryName": "Poland", "countryCode": "pl" } ] }, { "languageName": "Portuguese", "languageCode": "pt", "countries": [ { "countryName": "Portugal", "countryCode": "pt" }, { "countryName": "Brazil", "countryCode": "br" }, { "countryName": "Angola", "countryCode": "ao" }, { "countryName": "Cape Verde", "countryCode": "cv" }, { "countryName": "Guinea Equatorial", "countryCode": "cq" } ] }, { "languageName": "Punjabi", "languageCode": "pa", "countries": [ { "countryName": "India", "countryCode": "in" }, { "countryName": "Pakistan", "countryCode": "pk" } ] }, { "languageName": "Romanian", "languageCode": "ro", "countries": [ { "countryName": "Romania", "countryCode": "ro" } ] }, { "languageName": "Russian", "languageCode": "ru", "countries": [ { "countryName": "Russian Federation", "countryCode": "ru" }, { "countryName": "Belarus", "countryCode": "by" }, { "countryName": "Georgia", "countryCode": "ge" }, { "countryName": "Kazakhstan", "countryCode": "kz" }, { "countryName": "Kyrgyzstan", "countryCode": "kg" }, { "countryName": "Ukraine", "countryCode": "ua" } ] }, { "languageName": "Serbian", "languageCode": "sr", "countries": [ { "countryName": "Serbia", "countryCode": "latn-rs" }, { "countryName": "Montenegro", "countryCode": "latn-me" } ] }, { "languageName": "Slovak", "languageCode": "sk", "countries": [ { "countryName": "Slovakia", "countryCode": "sk" } ] }, { "languageName": "Slovenian", "languageCode": "sl", "countries": [ { "countryName": "Slovenia", "countryCode": "sl" } ] }, { "languageName": "Swedish", "languageCode": "sv", "countries": [ { "countryName": "Finland", "countryCode": "fi" }, { "countryName": "Sweden", "countryCode": "se" } ] }, { "languageName": "Tamil", "languageCode": "ta", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Telugu", "languageCode": "te", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Thai", "languageCode": "th", "countries": [ { "countryName": "Thailand", "countryCode": "th" } ] }, { "languageName": "Turkish", "languageCode": "tr", "countries": [ { "countryName": "Armenia", "countryCode": "am" }, { "countryName": "Azerbaijan", "countryCode": "az" }, { "countryName": "Cyprus", "countryCode": "cy" }, { "countryName": "Turkey", "countryCode": "tr" } ] }, { "languageName": "Urdu", "languageCode": "ur", "countries": [ { "countryName": "India", "countryCode": "in" }, { "countryName": "Pakistan", "countryCode": "pk" } ] }, { "languageName": "Ukranian", "languageCode": "uk", "countries": [ { "countryName": "Ukraine", "countryCode": "ua" } ] }, { "languageName": "Uzbek", "languageCode": "uz", "countries": [ { "countryName": "Uzbekistan", "countryCode": "cyrl-uz" }, { "countryName": "Uzbekistan", "countryCode": "latn-uz" } ] }, { "languageName": "Vietnamese", "languageCode": "vi", "countries": [ { "countryName": "Vietnam", "countryCode": "vn" } ] }, { "languageName": "中文", "languageCode": "zh", "countries": [ { "countryName": "简体", "countryCode": "cn" }, { "countryName": "繁体", "countryCode": "hk" }, { "countryName": "Malaysia", "countryCode": "my" }, { "countryName": "Singapore", "countryCode": "sg" }, { "countryName": "Taiwan", "countryCode": "tw" } ] } ]        
            };
        }
        else if(args.key == "timeZone") {
            message = { 
                "returnValue": true,
                "syszones": [ { "City": "", "Description": "GMT+14", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-14", "offsetFromUTC": 840 }, { "City": "", "Description": "GMT+13:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-13:30", "offsetFromUTC": 810 }, { "City": "", "Description": "GMT+13", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-13", "offsetFromUTC": 780 }, { "City": "", "Description": "GMT+12:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-12:30", "offsetFromUTC": 750 }, { "City": "", "Description": "GMT+12", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-12", "offsetFromUTC": 720 }, { "City": "", "Description": "GMT+11:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-11:30", "offsetFromUTC": 690 }, { "City": "", "Description": "GMT+11", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-11", "offsetFromUTC": 660 }, { "City": "", "Description": "GMT+10:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-10:30", "offsetFromUTC": 630 }, { "City": "", "Description": "GMT+10", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-10", "offsetFromUTC": 600 }, { "City": "", "Description": "GMT+9:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-9:30", "offsetFromUTC": 570 }, { "City": "", "Description": "GMT+9", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-9", "offsetFromUTC": 540 }, { "City": "", "Description": "GMT+8:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-8:30", "offsetFromUTC": 510 }, { "City": "", "Description": "GMT+8", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-8", "offsetFromUTC": 480 }, { "City": "", "Description": "GMT+7:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-7:30", "offsetFromUTC": 450 }, { "City": "", "Description": "GMT+7", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-7", "offsetFromUTC": 420 }, { "City": "", "Description": "GMT+6:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-6:30", "offsetFromUTC": 390 }, { "City": "", "Description": "GMT+6", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-6", "offsetFromUTC": 360 }, { "City": "", "Description": "GMT+5:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-5:30", "offsetFromUTC": 330 }, { "City": "", "Description": "GMT+5", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-5", "offsetFromUTC": 300 }, { "City": "", "Description": "GMT+4:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-4:30", "offsetFromUTC": 270 }, { "City": "", "Description": "GMT+4", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-4", "offsetFromUTC": 240 }, { "City": "", "Description": "GMT+3:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-3:30", "offsetFromUTC": 210 }, { "City": "", "Description": "GMT+3", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-3", "offsetFromUTC": 180 }, { "City": "", "Description": "GMT+2:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-2:30", "offsetFromUTC": 150 }, { "City": "", "Description": "GMT+2", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-2", "offsetFromUTC": 120 }, { "City": "", "Description": "GMT+1:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-1:30", "offsetFromUTC": 90 }, { "City": "", "Description": "GMT+1", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-1", "offsetFromUTC": 60 }, { "City": "", "Description": "GMT+0:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-0:30", "offsetFromUTC": 30 }, { "City": "", "Description": "GMT", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT-0", "offsetFromUTC": 0 }, { "City": "", "Description": "GMT", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+0", "offsetFromUTC": 0 }, { "City": "", "Description": "GMT-0:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+0:30", "offsetFromUTC": -30 }, { "City": "", "Description": "GMT-1", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+1", "offsetFromUTC": -60 }, { "City": "", "Description": "GMT-1:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+1:30", "offsetFromUTC": -90 }, { "City": "", "Description": "GMT-2", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+2", "offsetFromUTC": -120 }, { "City": "", "Description": "GMT-2:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+2:30", "offsetFromUTC": -150 }, { "City": "", "Description": "GMT-3", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+3", "offsetFromUTC": -180 }, { "City": "", "Description": "GMT-3:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+3:30", "offsetFromUTC": -210 }, { "City": "", "Description": "GMT-4", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+4", "offsetFromUTC": -240 }, { "City": "", "Description": "GMT-4:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+4:30", "offsetFromUTC": -270 }, { "City": "", "Description": "GMT-5", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+5", "offsetFromUTC": -300 }, { "City": "", "Description": "GMT-5:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+5:30", "offsetFromUTC": -330 }, { "City": "", "Description": "GMT-6", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+6", "offsetFromUTC": -360 }, { "City": "", "Description": "GMT-6:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+6:30", "offsetFromUTC": -390 }, { "City": "", "Description": "GMT-7", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+7", "offsetFromUTC": -420 }, { "City": "", "Description": "GMT-7:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+7:30", "offsetFromUTC": -450 }, { "City": "", "Description": "GMT-8", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+8", "offsetFromUTC": -480 }, { "City": "", "Description": "GMT-8:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+8:30", "offsetFromUTC": -510 }, { "City": "", "Description": "GMT-9", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+9", "offsetFromUTC": -540 }, { "City": "", "Description": "GMT-9:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+9:30", "offsetFromUTC": -570 }, { "City": "", "Description": "GMT-10", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+10", "offsetFromUTC": -600 }, { "City": "", "Description": "GMT-10:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+10:30", "offsetFromUTC": -630 }, { "City": "", "Description": "GMT-11", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+11", "offsetFromUTC": -660 }, { "City": "", "Description": "GMT-11:30", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+11:30", "offsetFromUTC": -690 }, { "City": "", "Description": "GMT-12", "CountryCode": "", "Country": "", "supportsDST": 0, "ZoneID": "Etc\/GMT+12", "offsetFromUTC": -720 } ],
                "timeZone": [ { "City": "Tahiti", "Description": "Tahiti Time", "CountryCode": "PF", "Country": "French Polynesia", "supportsDST": 0, "ZoneID": "Pacific\/Tahiti", "offsetFromUTC": -600 }, { "City": "Adak", "Description": "Hawaii-Aleutian Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 1, "ZoneID": "America\/Adak", "offsetFromUTC": -600, "preferred": true }, { "City": "Honolulu", "Description": "Hawaii Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 0, "ZoneID": "Pacific\/Honolulu", "offsetFromUTC": -600, "preferred": true }, { "City": "Marquesas", "Description": "Marquesas Time", "CountryCode": "PF", "Country": "French Polynesia", "supportsDST": 0, "ZoneID": "Pacific\/Marquesas", "offsetFromUTC": -570, "preferred": true }, { "City": "Gambier", "Description": "Gambier Time", "CountryCode": "PF", "Country": "French Polynesia", "supportsDST": 0, "ZoneID": "Pacific\/Gambier", "offsetFromUTC": -540 }, { "City": "Anchorage", "Description": "Alaska Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 1, "ZoneID": "America\/Anchorage", "offsetFromUTC": -540, "preferred": true }, { "City": "Tijuana", "Description": "Pacific Time", "CountryCode": "MX", "Country": "Mexico", "supportsDST": 1, "ZoneID": "America\/Tijuana", "offsetFromUTC": -480 }, { "City": "Vancouver", "Description": "Pacific Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Vancouver", "offsetFromUTC": -480 }, { "City": "Dawson", "Description": "Pacific Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Dawson", "offsetFromUTC": -480 }, { "City": "Los Angeles", "Description": "Pacific Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 1, "ZoneID": "America\/Los_Angeles", "offsetFromUTC": -480, "preferred": true }, { "City": "Mazatlán", "Description": "Mountain Time", "CountryCode": "MX", "Country": "Mexico", "supportsDST": 1, "ZoneID": "America\/Mazatlan", "offsetFromUTC": -420 }, { "City": "Chihuahua", "Description": "Mountain Time", "CountryCode": "MX", "Country": "Mexico", "supportsDST": 1, "ZoneID": "America\/Chihuahua", "offsetFromUTC": -420 }, { "City": "Hermosillo", "Description": "Mountain Time", "CountryCode": "MX", "Country": "Mexico", "supportsDST": 0, "ZoneID": "America\/Hermosillo", "offsetFromUTC": -420 }, { "City": "Edmonton", "Description": "Mountain Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Edmonton", "offsetFromUTC": -420 }, { "City": "Yellowknife", "Description": "Mountain Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Yellowknife", "offsetFromUTC": -420 }, { "City": "Dawson Creek", "Description": "Mountain Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 0, "ZoneID": "America\/Dawson_Creek", "offsetFromUTC": -420 }, { "City": "Denver", "Description": "Mountain Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 1, "ZoneID": "America\/Denver", "offsetFromUTC": -420, "preferred": true }, { "City": "Phoenix", "Description": "Mountain Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 0, "ZoneID": "America\/Phoenix", "offsetFromUTC": -420, "preferred": true }, { "City": "", "Description": "Central Time", "CountryCode": "BZ", "Country": "Belize", "supportsDST": 0, "ZoneID": "America\/Belize", "offsetFromUTC": -360 }, { "City": "Guatemala City", "Description": "Central Time", "CountryCode": "GT", "Country": "Guatemala", "supportsDST": 0, "ZoneID": "America\/Guatemala", "offsetFromUTC": -360 }, { "City": "San Salvador", "Description": "Central Time", "CountryCode": "SV", "Country": "El Salvador", "supportsDST": 0, "ZoneID": "America\/El_Salvador", "offsetFromUTC": -360 }, { "City": "Tegucigalpa", "Description": "Central Time", "CountryCode": "HN", "Country": "Honduras", "supportsDST": 0, "ZoneID": "America\/Tegucigalpa", "offsetFromUTC": -360 }, { "City": "Galapagos Islands", "Description": "Galapagos Time", "CountryCode": "EC", "Country": "Ecuador", "supportsDST": 0, "ZoneID": "Pacific\/Galapagos", "offsetFromUTC": -360 }, { "City": "Mexico City", "Description": "Central Time", "CountryCode": "MX", "Country": "Mexico", "supportsDST": 1, "ZoneID": "America\/Mexico_City", "offsetFromUTC": -360 }, { "City": "Mérida", "Description": "Central Time", "CountryCode": "MX", "Country": "Mexico", "supportsDST": 1, "ZoneID": "America\/Merida", "offsetFromUTC": -360 }, { "City": "Monterrey", "Description": "Central Time", "CountryCode": "MX", "Country": "Mexico", "supportsDST": 1, "ZoneID": "America\/Monterrey", "offsetFromUTC": -360 }, { "City": "Managua", "Description": "Central Time", "CountryCode": "NI", "Country": "Nicaragua", "supportsDST": 0, "ZoneID": "America\/Managua", "offsetFromUTC": -360 }, { "City": "Easter Island", "Description": "Easter Island Time", "CountryCode": "CL", "Country": "Chile", "supportsDST": 1, "ZoneID": "Pacific\/Easter", "offsetFromUTC": -360 }, { "City": "Winnipeg", "Description": "Central Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Winnipeg", "offsetFromUTC": -360 }, { "City": "Rainy River", "Description": "Central Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Rainy_River", "offsetFromUTC": -360 }, { "City": "Regina", "Description": "Central Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 0, "ZoneID": "America\/Regina", "offsetFromUTC": -360, "preferred": true }, { "City": "Swift Current", "Description": "Central Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 0, "ZoneID": "America\/Swift_Current", "offsetFromUTC": -360 }, { "City": "", "Description": "Central Time", "CountryCode": "CR", "Country": "Costa Rica", "supportsDST": 0, "ZoneID": "America\/Costa_Rica", "offsetFromUTC": -360 }, { "City": "Chicago", "Description": "Central Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 1, "ZoneID": "America\/Chicago", "offsetFromUTC": -360, "preferred": true }, { "City": "Jamaica", "Description": "Eastern Time", "CountryCode": "JM", "Country": "Jamaica", "supportsDST": 0, "ZoneID": "America\/Jamaica", "offsetFromUTC": -300 }, { "City": "Eirunepé", "Description": "Acre Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Eirunepe", "offsetFromUTC": -300 }, { "City": "Rio Branco", "Description": "Acre Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Rio_Branco", "offsetFromUTC": -300 }, { "City": "Nassau", "Description": "Eastern Time", "CountryCode": "BS", "Country": "Bahamas", "supportsDST": 1, "ZoneID": "America\/Nassau", "offsetFromUTC": -300 }, { "City": "Port-au-Prince", "Description": "Eastern Time", "CountryCode": "HT", "Country": "Haiti", "supportsDST": 0, "ZoneID": "America\/Port-au-Prince", "offsetFromUTC": -300 }, { "City": "Panama City", "Description": "Eastern Time", "CountryCode": "PA", "Country": "Panama", "supportsDST": 0, "ZoneID": "America\/Panama", "offsetFromUTC": -300 }, { "City": "Lima", "Description": "Peru Time", "CountryCode": "PE", "Country": "Peru", "supportsDST": 0, "ZoneID": "America\/Lima", "offsetFromUTC": -300 }, { "City": "Guayaquil", "Description": "Ecuador Time", "CountryCode": "EC", "Country": "Ecuador", "supportsDST": 0, "ZoneID": "America\/Guayaquil", "offsetFromUTC": -300 }, { "City": "Cancún", "Description": "Central Time", "CountryCode": "MX", "Country": "Mexico", "supportsDST": 0, "ZoneID": "America\/Cancun", "offsetFromUTC": -300 }, { "City": "Bogotá", "Description": "Colombia Time", "CountryCode": "CO", "Country": "Colombia", "supportsDST": 0, "ZoneID": "America\/Bogota", "offsetFromUTC": -300 }, { "City": "Toronto", "Description": "Eastern Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Toronto", "offsetFromUTC": -300 }, { "City": "Nipigon", "Description": "Eastern Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Nipigon", "offsetFromUTC": -300 }, { "City": "Atikokan", "Description": "Eastern Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 0, "ZoneID": "America\/Atikokan", "offsetFromUTC": -300 }, { "City": "Havana", "Description": "Cuba Time", "CountryCode": "CU", "Country": "Cuba", "supportsDST": 1, "ZoneID": "America\/Havana", "offsetFromUTC": -300 }, { "City": "", "Description": "Eastern Time", "CountryCode": "KY", "Country": "Cayman Islands", "supportsDST": 0, "ZoneID": "America\/Cayman", "offsetFromUTC": -300 }, { "City": "New York", "Description": "Eastern Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 1, "ZoneID": "America\/New_York", "offsetFromUTC": -300, "preferred": true }, { "City": "Detroit", "Description": "Eastern Time", "CountryCode": "US", "Country": "United States of America", "supportsDST": 1, "ZoneID": "America\/Detroit", "offsetFromUTC": -300 }, { "City": "Caracas", "Description": "Venezuela Time", "CountryCode": "VE", "Country": "Venezuela", "supportsDST": 0, "ZoneID": "America\/Caracas", "offsetFromUTC": -270, "preferred": true }, { "City": "", "Description": "Atlantic Time", "CountryCode": "BB", "Country": "Barbados", "supportsDST": 0, "ZoneID": "America\/Barbados", "offsetFromUTC": -240 }, { "City": "", "Description": "Atlantic Time", "CountryCode": "BM", "Country": "Bermuda", "supportsDST": 1, "ZoneID": "Atlantic\/Bermuda", "offsetFromUTC": -240 }, { "City": "La Paz", "Description": "Bolivia Time", "CountryCode": "BO", "Country": "Bolivia", "supportsDST": 0, "ZoneID": "America\/La_Paz", "offsetFromUTC": -240 }, { "City": "Campo Grande", "Description": "Amazon Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 1, "ZoneID": "America\/Campo_Grande", "offsetFromUTC": -240 }, { "City": "Cuiabá", "Description": "Amazon Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 1, "ZoneID": "America\/Cuiaba", "offsetFromUTC": -240 }, { "City": "Porto Velho", "Description": "Amazon Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Porto_Velho", "offsetFromUTC": -240 }, { "City": "Boa Vista", "Description": "Amazon Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Boa_Vista", "offsetFromUTC": -240 }, { "City": "Manaus", "Description": "Amazon Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Manaus", "offsetFromUTC": -240 }, { "City": "", "Description": "Atlantic Time", "CountryCode": "GP", "Country": "Guadeloupe", "supportsDST": 0, "ZoneID": "America\/Guadeloupe", "offsetFromUTC": -240 }, { "City": "", "Description": "Guyana Time", "CountryCode": "GY", "Country": "Guyana", "supportsDST": 0, "ZoneID": "America\/Guyana", "offsetFromUTC": -240 }, { "City": "Thule", "Description": "Atlantic Time", "CountryCode": "GL", "Country": "Greenland", "supportsDST": 1, "ZoneID": "America\/Thule", "offsetFromUTC": -240 }, { "City": "", "Description": "Atlantic Time", "CountryCode": "PR", "Country": "Puerto Rico", "supportsDST": 0, "ZoneID": "America\/Puerto_Rico", "offsetFromUTC": -240 }, { "City": "Asunción", "Description": "Paraguay Time", "CountryCode": "PY", "Country": "Paraguay", "supportsDST": 1, "ZoneID": "America\/Asuncion", "offsetFromUTC": -240 }, { "City": "", "Description": "Atlantic Time", "CountryCode": "MQ", "Country": "Martinique", "supportsDST": 0, "ZoneID": "America\/Martinique", "offsetFromUTC": -240 }, { "City": "Santiago", "Description": "Chile Time", "CountryCode": "CL", "Country": "Chile", "supportsDST": 1, "ZoneID": "America\/Santiago", "offsetFromUTC": -240 }, { "City": "Halifax", "Description": "Atlantic Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Halifax", "offsetFromUTC": -240, "preferred": true }, { "City": "Glace Bay", "Description": "Atlantic Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Glace_Bay", "offsetFromUTC": -240 }, { "City": "Moncton", "Description": "Atlantic Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/Moncton", "offsetFromUTC": -240 }, { "City": "Blanc-Sablon", "Description": "Atlantic Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 0, "ZoneID": "America\/Blanc-Sablon", "offsetFromUTC": -240 }, { "City": "Santo Domingo", "Description": "Atlantic Time", "CountryCode": "DO", "Country": "Dominican Republic", "supportsDST": 0, "ZoneID": "America\/Santo_Domingo", "offsetFromUTC": -240 }, { "City": "", "Description": "Atlantic Time", "CountryCode": "DM", "Country": "Dominica", "supportsDST": 0, "ZoneID": "America\/Dominica", "offsetFromUTC": -240 }, { "City": "", "Description": "Atlantic Time", "CountryCode": "LC", "Country": "Saint Lucia", "supportsDST": 0, "ZoneID": "America\/St_Lucia", "offsetFromUTC": -240 }, { "City": "Port of Spain", "Description": "Atlantic Time", "CountryCode": "TT", "Country": "Trinidad And Tobago", "supportsDST": 0, "ZoneID": "America\/Port_of_Spain", "offsetFromUTC": -240 }, { "City": "Oranjestad", "Description": "Atlantic Time", "CountryCode": "AW", "Country": "Aruba", "supportsDST": 0, "ZoneID": "America\/Aruba", "offsetFromUTC": -240, "preferred": true }, { "City": "St. John's", "Description": "Newfoundland Time", "CountryCode": "CA", "Country": "Canada", "supportsDST": 1, "ZoneID": "America\/St_Johns", "offsetFromUTC": -210, "preferred": true }, { "City": "Belém", "Description": "Brasilia Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Belem", "offsetFromUTC": -180 }, { "City": "Fortaleza", "Description": "Brasilia Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Fortaleza", "offsetFromUTC": -180 }, { "City": "Recife", "Description": "Brasilia Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Recife", "offsetFromUTC": -180 }, { "City": "Araguaína", "Description": "Brasilia Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Araguaina", "offsetFromUTC": -180 }, { "City": "Maceió ", "Description": "Brasilia Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Maceio", "offsetFromUTC": -180 }, { "City": "São Paulo", "Description": "Brasilia Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 1, "ZoneID": "America\/Sao_Paulo", "offsetFromUTC": -180, "preferred": true }, { "City": "Godthab", "Description": "Western Greenland Time", "CountryCode": "GL", "Country": "Greenland", "supportsDST": 1, "ZoneID": "America\/Godthab", "offsetFromUTC": -180 }, { "City": "Paramaribo", "Description": "Suriname Time", "CountryCode": "SR", "Country": "Suriname", "supportsDST": 0, "ZoneID": "America\/Paramaribo", "offsetFromUTC": -180, "preferred": true }, { "City": "Montevideo", "Description": "Uruguay Time", "CountryCode": "UY", "Country": "Uruguay", "supportsDST": 0, "ZoneID": "America\/Montevideo", "offsetFromUTC": -180 }, { "City": "San Luis", "Description": "San Luis Time", "CountryCode": "AR", "Country": "Argentina", "supportsDST": 0, "ZoneID": "America\/Argentina\/San_Luis", "offsetFromUTC": -180 }, { "City": "Fernando de Noronha", "Description": "Fernando de Noronha Time", "CountryCode": "BR", "Country": "Brazil", "supportsDST": 0, "ZoneID": "America\/Noronha", "offsetFromUTC": -120, "preferred": true }, { "City": "Scoresbysund", "Description": "Eastern Greenland Time", "CountryCode": "GL", "Country": "Greenland", "supportsDST": 1, "ZoneID": "America\/Scoresbysund", "offsetFromUTC": -60 }, { "City": "Azores", "Description": "Azores Time", "CountryCode": "PT", "Country": "Portugal", "supportsDST": 1, "ZoneID": "Atlantic\/Azores", "offsetFromUTC": -60, "preferred": true }, { "City": "", "Description": "Cape Verde Time", "CountryCode": "CV", "Country": "Cape Verde", "supportsDST": 0, "ZoneID": "Atlantic\/Cape_Verde", "offsetFromUTC": -60, "preferred": true }, { "City": "Ouagadougou", "Description": "Greenwich Mean Time", "CountryCode": "BF", "Country": "Burkina Faso", "supportsDST": 0, "ZoneID": "Africa\/Ouagadougou", "offsetFromUTC": 0 }, { "City": "", "Description": "Greenwich Mean Time", "CountryCode": "GG", "Country": "Guernsey", "supportsDST": 1, "ZoneID": "Europe\/Guernsey", "offsetFromUTC": 0 }, { "City": "London", "Description": "Greenwich Mean Time", "CountryCode": "GB", "Country": "United Kingdom", "supportsDST": 1, "ZoneID": "Europe\/London", "offsetFromUTC": 0, "preferred": true }, { "City": "Banjul", "Description": "Greenwich Mean Time", "CountryCode": "GM", "Country": "Gambia", "supportsDST": 0, "ZoneID": "Africa\/Banjul", "offsetFromUTC": 0 }, { "City": "Danmarkshavn", "Description": "Greenwich Mean Time", "CountryCode": "GL", "Country": "Greenland", "supportsDST": 0, "ZoneID": "America\/Danmarkshavn", "offsetFromUTC": 0 }, { "City": "Accra", "Description": "Ghana Mean Time", "CountryCode": "GH", "Country": "Ghana", "supportsDST": 0, "ZoneID": "Africa\/Accra", "offsetFromUTC": 0 }, { "City": "Lisbon", "Description": "Western European Time", "CountryCode": "PT", "Country": "Portugal", "supportsDST": 1, "ZoneID": "Europe\/Lisbon", "offsetFromUTC": 0 }, { "City": "Madeira", "Description": "Western European Time", "CountryCode": "PT", "Country": "Portugal", "supportsDST": 1, "ZoneID": "Atlantic\/Madeira", "offsetFromUTC": 0 }, { "City": "Canary Islands", "Description": "Western European Time", "CountryCode": "ES", "Country": "Spain", "supportsDST": 1, "ZoneID": "Atlantic\/Canary", "offsetFromUTC": 0 }, { "City": "Casablanca", "Description": "Western European Time", "CountryCode": "MA", "Country": "Morocco", "supportsDST": 1, "ZoneID": "Africa\/Casablanca", "offsetFromUTC": 0 }, { "City": "Bamako", "Description": "Greenwich Mean Time", "CountryCode": "ML", "Country": "Mali", "supportsDST": 0, "ZoneID": "Africa\/Bamako", "offsetFromUTC": 0 }, { "City": "Abidjan", "Description": "Greenwich Mean Time", "CountryCode": "CI", "Country": "Côte d'Ivoire", "supportsDST": 0, "ZoneID": "Africa\/Abidjan", "offsetFromUTC": 0 }, { "City": "Dakar", "Description": "Greenwich Mean Time", "CountryCode": "SN", "Country": "Senegal", "supportsDST": 0, "ZoneID": "Africa\/Dakar", "offsetFromUTC": 0 }, { "City": "Freetown", "Description": "Greenwich Mean Time", "CountryCode": "SL", "Country": "Sierra Leone", "supportsDST": 0, "ZoneID": "Africa\/Freetown", "offsetFromUTC": 0 }, { "City": "Monrovia", "Description": "Greenwich Mean Time", "CountryCode": "LR", "Country": "Liberia", "supportsDST": 0, "ZoneID": "Africa\/Monrovia", "offsetFromUTC": 0 }, { "City": "Reykjavik", "Description": "Greenwich Mean Time", "CountryCode": "IS", "Country": "Iceland", "supportsDST": 0, "ZoneID": "Atlantic\/Reykjavik", "offsetFromUTC": 0 }, { "City": "Dublin", "Description": "Greenwich Mean Time", "CountryCode": "IE", "Country": "Ireland", "supportsDST": 1, "ZoneID": "Europe\/Dublin", "offsetFromUTC": 0 }, { "City": "Brussels", "Description": "Central European Time", "CountryCode": "BE", "Country": "Belgium", "supportsDST": 1, "ZoneID": "Europe\/Brussels", "offsetFromUTC": 60 }, { "City": "Sarajevo", "Description": "Central European Time", "CountryCode": "BA", "Country": "Bosnia And Herzegovina", "supportsDST": 1, "ZoneID": "Europe\/Sarajevo", "offsetFromUTC": 60 }, { "City": "Porto-Novo", "Description": "Western African Time", "CountryCode": "BJ", "Country": "Benin", "supportsDST": 0, "ZoneID": "Africa\/Porto-Novo", "offsetFromUTC": 60 }, { "City": "Belgrade", "Description": "Central European Time", "CountryCode": "RS", "Country": "Serbia", "supportsDST": 1, "ZoneID": "Europe\/Belgrade", "offsetFromUTC": 60 }, { "City": "Malabo", "Description": "Western African Time", "CountryCode": "GQ", "Country": "Equatorial Guinea", "supportsDST": 0, "ZoneID": "Africa\/Malabo", "offsetFromUTC": 60 }, { "City": "Libreville", "Description": "Western African Time", "CountryCode": "GA", "Country": "Gabon", "supportsDST": 0, "ZoneID": "Africa\/Libreville", "offsetFromUTC": 60 }, { "City": "Gibraltar", "Description": "Central European Time", "CountryCode": "GI", "Country": "Gibraltar", "supportsDST": 1, "ZoneID": "Europe\/Gibraltar", "offsetFromUTC": 60 }, { "City": "Tunis", "Description": "Central European Time", "CountryCode": "TN", "Country": "Tunisia", "supportsDST": 0, "ZoneID": "Africa\/Tunis", "offsetFromUTC": 60 }, { "City": "Zagreb", "Description": "Central European Time", "CountryCode": "HR", "Country": "Croatia", "supportsDST": 1, "ZoneID": "Europe\/Zagreb", "offsetFromUTC": 60 }, { "City": "Budapest", "Description": "Central European Time", "CountryCode": "HU", "Country": "Hungary", "supportsDST": 1, "ZoneID": "Europe\/Budapest", "offsetFromUTC": 60 }, { "City": "Warsaw", "Description": "Central European Time", "CountryCode": "PL", "Country": "Poland", "supportsDST": 1, "ZoneID": "Europe\/Warsaw", "offsetFromUTC": 60 }, { "City": "Rome", "Description": "Central European Time", "CountryCode": "IT", "Country": "Italy", "supportsDST": 1, "ZoneID": "Europe\/Rome", "offsetFromUTC": 60 }, { "City": "Madrid", "Description": "Central European Time", "CountryCode": "ES", "Country": "Spain", "supportsDST": 1, "ZoneID": "Europe\/Madrid", "offsetFromUTC": 60 }, { "City": "Ceuta", "Description": "Central European Time", "CountryCode": "ES", "Country": "Spain", "supportsDST": 1, "ZoneID": "Africa\/Ceuta", "offsetFromUTC": 60 }, { "City": "Podgorica", "Description": "Central European Time", "CountryCode": "ME", "Country": "Montenegro", "supportsDST": 1, "ZoneID": "Europe\/Podgorica", "offsetFromUTC": 60 }, { "City": "Monaco", "Description": "Central European Time", "CountryCode": "MC", "Country": "Monaco", "supportsDST": 1, "ZoneID": "Europe\/Monaco", "offsetFromUTC": 60 }, { "City": "Skopje", "Description": "Central European Time", "CountryCode": "MK", "Country": "Macedonia, The Former Yugoslav Republic Of", "supportsDST": 1, "ZoneID": "Europe\/Skopje", "offsetFromUTC": 60 }, { "City": "", "Description": "Central European Time", "CountryCode": "MT", "Country": "Malta", "supportsDST": 1, "ZoneID": "Europe\/Malta", "offsetFromUTC": 60 }, { "City": "Paris", "Description": "Central European Time", "CountryCode": "FR", "Country": "France", "supportsDST": 1, "ZoneID": "Europe\/Paris", "offsetFromUTC": 60, "preferred": true }, { "City": "Amsterdam", "Description": "Central European Time", "CountryCode": "NL", "Country": "Netherlands", "supportsDST": 1, "ZoneID": "Europe\/Amsterdam", "offsetFromUTC": 60 }, { "City": "Oslo", "Description": "Central European Time", "CountryCode": "NO", "Country": "Norway", "supportsDST": 1, "ZoneID": "Europe\/Oslo", "offsetFromUTC": 60 }, { "City": "Windhoek", "Description": "Western African Time", "CountryCode": "NA", "Country": "Namibia", "supportsDST": 1, "ZoneID": "Africa\/Windhoek", "offsetFromUTC": 60 }, { "City": "Niamey", "Description": "Western African Time", "CountryCode": "NE", "Country": "Niger", "supportsDST": 0, "ZoneID": "Africa\/Niamey", "offsetFromUTC": 60 }, { "City": "Lagos", "Description": "Western African Time", "CountryCode": "NG", "Country": "Nigeria", "supportsDST": 0, "ZoneID": "Africa\/Lagos", "offsetFromUTC": 60 }, { "City": "Zürich", "Description": "Central European Time", "CountryCode": "CH", "Country": "Switzerland", "supportsDST": 1, "ZoneID": "Europe\/Zurich", "offsetFromUTC": 60 }, { "City": "Douala", "Description": "Western African Time", "CountryCode": "CM", "Country": "Cameroon", "supportsDST": 0, "ZoneID": "Africa\/Douala", "offsetFromUTC": 60 }, { "City": "Brazzaville", "Description": "Western African Time", "CountryCode": "CG", "Country": "Republic Of The Congo", "supportsDST": 0, "ZoneID": "Africa\/Brazzaville", "offsetFromUTC": 60 }, { "City": "Bangui", "Description": "Western African Time", "CountryCode": "CF", "Country": "Central African Republic", "supportsDST": 0, "ZoneID": "Africa\/Bangui", "offsetFromUTC": 60 }, { "City": "Kinshasa", "Description": "Western African Time", "CountryCode": "CD", "Country": "Democratic Republic Of The Congo", "supportsDST": 0, "ZoneID": "Africa\/Kinshasa", "offsetFromUTC": 60 }, { "City": "Prague", "Description": "Central European Time", "CountryCode": "CZ", "Country": "Czech Republic", "supportsDST": 1, "ZoneID": "Europe\/Prague", "offsetFromUTC": 60 }, { "City": "Bratislava", "Description": "Central European Time", "CountryCode": "SK", "Country": "Slovakia", "supportsDST": 1, "ZoneID": "Europe\/Bratislava", "offsetFromUTC": 60 }, { "City": "Ljubljana", "Description": "Central European Time", "CountryCode": "SI", "Country": "Slovenia", "supportsDST": 1, "ZoneID": "Europe\/Ljubljana", "offsetFromUTC": 60 }, { "City": "Stockholm", "Description": "Central European Time", "CountryCode": "SE", "Country": "Sweden", "supportsDST": 1, "ZoneID": "Europe\/Stockholm", "offsetFromUTC": 60 }, { "City": "Copenhagen", "Description": "Central European Time", "CountryCode": "DK", "Country": "Denmark", "supportsDST": 1, "ZoneID": "Europe\/Copenhagen", "offsetFromUTC": 60 }, { "City": "Berlin", "Description": "Central European Time", "CountryCode": "DE", "Country": "Germany", "supportsDST": 1, "ZoneID": "Europe\/Berlin", "offsetFromUTC": 60 }, { "City": "Algiers", "Description": "Central European Time", "CountryCode": "DZ", "Country": "Algeria", "supportsDST": 0, "ZoneID": "Africa\/Algiers", "offsetFromUTC": 60 }, { "City": "Vaduz", "Description": "Central European Time", "CountryCode": "LI", "Country": "Liechtenstein", "supportsDST": 1, "ZoneID": "Europe\/Vaduz", "offsetFromUTC": 60 }, { "City": "Luxembourg", "Description": "Central European Time", "CountryCode": "LU", "Country": "Luxembourg", "supportsDST": 1, "ZoneID": "Europe\/Luxembourg", "offsetFromUTC": 60 }, { "City": "Ndjamena", "Description": "Western African Time", "CountryCode": "TD", "Country": "Chad", "supportsDST": 0, "ZoneID": "Africa\/Ndjamena", "offsetFromUTC": 60 }, { "City": "Vatican City", "Description": "Central European Time", "CountryCode": "VA", "Country": "Vatican City", "supportsDST": 1, "ZoneID": "Europe\/Vatican", "offsetFromUTC": 60 }, { "City": "Tiranë", "Description": "Central European Time", "CountryCode": "AL", "Country": "Albania", "supportsDST": 1, "ZoneID": "Europe\/Tirane", "offsetFromUTC": 60 }, { "City": "Luanda", "Description": "Western African Time", "CountryCode": "AO", "Country": "Angola", "supportsDST": 0, "ZoneID": "Africa\/Luanda", "offsetFromUTC": 60 }, { "City": "Vienna", "Description": "Central European Time", "CountryCode": "AT", "Country": "Austria", "supportsDST": 1, "ZoneID": "Europe\/Vienna", "offsetFromUTC": 60 }, { "City": "Sofia", "Description": "Eastern European Time", "CountryCode": "BG", "Country": "Bulgaria", "supportsDST": 1, "ZoneID": "Europe\/Sofia", "offsetFromUTC": 120 }, { "City": "Bujumbura", "Description": "Central African Time", "CountryCode": "BI", "Country": "Burundi", "supportsDST": 0, "ZoneID": "Africa\/Bujumbura", "offsetFromUTC": 120 }, { "City": "Gaborone", "Description": "Central African Time", "CountryCode": "BW", "Country": "Botswana", "supportsDST": 0, "ZoneID": "Africa\/Gaborone", "offsetFromUTC": 120 }, { "City": "Kaliningrad", "Description": "Eastern European Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Europe\/Kaliningrad", "offsetFromUTC": 120 }, { "City": "Kigali", "Description": "Central African Time", "CountryCode": "RW", "Country": "Rwanda", "supportsDST": 0, "ZoneID": "Africa\/Kigali", "offsetFromUTC": 120 }, { "City": "Bucharest", "Description": "Eastern European Time", "CountryCode": "RO", "Country": "Romania", "supportsDST": 1, "ZoneID": "Europe\/Bucharest", "offsetFromUTC": 120 }, { "City": "Athens", "Description": "Eastern European Time", "CountryCode": "GR", "Country": "Greece", "supportsDST": 1, "ZoneID": "Europe\/Athens", "offsetFromUTC": 120, "preferred": true }, { "City": "Amman", "Description": "Eastern European Time", "CountryCode": "JO", "Country": "Jordan", "supportsDST": 0, "ZoneID": "Asia\/Amman", "offsetFromUTC": 120 }, { "City": "Lusaka", "Description": "Central African Time", "CountryCode": "ZM", "Country": "Zambia", "supportsDST": 0, "ZoneID": "Africa\/Lusaka", "offsetFromUTC": 120 }, { "City": "Tallinn", "Description": "Eastern European Time", "CountryCode": "EE", "Country": "Estonia", "supportsDST": 1, "ZoneID": "Europe\/Tallinn", "offsetFromUTC": 120 }, { "City": "Cairo", "Description": "Eastern European Time", "CountryCode": "EG", "Country": "Egypt", "supportsDST": 0, "ZoneID": "Africa\/Cairo", "offsetFromUTC": 120 }, { "City": "Johannesburg", "Description": "South Africa Time", "CountryCode": "ZA", "Country": "South Africa", "supportsDST": 0, "ZoneID": "Africa\/Johannesburg", "offsetFromUTC": 120 }, { "City": "Harare", "Description": "Central African Time", "CountryCode": "ZW", "Country": "Zimbabwe", "supportsDST": 0, "ZoneID": "Africa\/Harare", "offsetFromUTC": 120 }, { "City": "Chisinau", "Description": "Eastern European Time", "CountryCode": "MD", "Country": "Moldova", "supportsDST": 1, "ZoneID": "Europe\/Chisinau", "offsetFromUTC": 120 }, { "City": "Blantyre", "Description": "Central African Time", "CountryCode": "MW", "Country": "Malawi", "supportsDST": 0, "ZoneID": "Africa\/Blantyre", "offsetFromUTC": 120 }, { "City": "Jerusalem", "Description": "Israel Time", "CountryCode": "IL", "Country": "Israel", "supportsDST": 1, "ZoneID": "Asia\/Jerusalem", "offsetFromUTC": 120 }, { "City": "Helsinki", "Description": "Eastern European Time", "CountryCode": "FI", "Country": "Finland", "supportsDST": 1, "ZoneID": "Europe\/Helsinki", "offsetFromUTC": 120 }, { "City": "Lubumbashi", "Description": "Central African Time", "CountryCode": "CD", "Country": "Democratic Republic Of The Congo", "supportsDST": 0, "ZoneID": "Africa\/Lubumbashi", "offsetFromUTC": 120 }, { "City": "Nicosia", "Description": "Eastern European Time", "CountryCode": "CY", "Country": "Cyprus", "supportsDST": 1, "ZoneID": "Asia\/Nicosia", "offsetFromUTC": 120 }, { "City": "Mbabane", "Description": "South Africa Time", "CountryCode": "SZ", "Country": "Swaziland", "supportsDST": 0, "ZoneID": "Africa\/Mbabane", "offsetFromUTC": 120 }, { "City": "Damascus", "Description": "Eastern European Time", "CountryCode": "SY", "Country": "Syria", "supportsDST": 1, "ZoneID": "Asia\/Damascus", "offsetFromUTC": 120 }, { "City": "Beirut", "Description": "Eastern European Time", "CountryCode": "LB", "Country": "Lebanon", "supportsDST": 1, "ZoneID": "Asia\/Beirut", "offsetFromUTC": 120 }, { "City": "Istanbul", "Description": "Eastern European Time", "CountryCode": "TR", "Country": "Turkey", "supportsDST": 1, "ZoneID": "Europe\/Istanbul", "offsetFromUTC": 120 }, { "City": "Riga", "Description": "Eastern European Time", "CountryCode": "LV", "Country": "Latvia", "supportsDST": 1, "ZoneID": "Europe\/Riga", "offsetFromUTC": 120 }, { "City": "Vilnius", "Description": "Eastern European Time", "CountryCode": "LT", "Country": "Lithuania", "supportsDST": 1, "ZoneID": "Europe\/Vilnius", "offsetFromUTC": 120 }, { "City": "Maseru", "Description": "South Africa Time", "CountryCode": "LS", "Country": "Lesotho", "supportsDST": 0, "ZoneID": "Africa\/Maseru", "offsetFromUTC": 120 }, { "City": "Tripoli", "Description": "Eastern European Time", "CountryCode": "LY", "Country": "Libya", "supportsDST": 0, "ZoneID": "Africa\/Tripoli", "offsetFromUTC": 120 }, { "City": "Kiev", "Description": "Eastern European Time", "CountryCode": "UA", "Country": "Ukraine", "supportsDST": 1, "ZoneID": "Europe\/Kiev", "offsetFromUTC": 120 }, { "City": "Uzhhorod", "Description": "Eastern European Time", "CountryCode": "UA", "Country": "Ukraine", "supportsDST": 1, "ZoneID": "Europe\/Uzhgorod", "offsetFromUTC": 120 }, { "City": "Zaporozhye", "Description": "Eastern European Time", "CountryCode": "UA", "Country": "Ukraine", "supportsDST": 1, "ZoneID": "Europe\/Zaporozhye", "offsetFromUTC": 120 }, { "City": "Maputo", "Description": "Central African Time", "CountryCode": "MZ", "Country": "Mozambique", "supportsDST": 0, "ZoneID": "Africa\/Maputo", "offsetFromUTC": 120 }, { "City": "", "Description": "Arabia Time", "CountryCode": "BH", "Country": "Bahrain", "supportsDST": 0, "ZoneID": "Asia\/Bahrain", "offsetFromUTC": 180 }, { "City": "Minsk", "Description": "Eastern European Time", "CountryCode": "BY", "Country": "Belarus", "supportsDST": 0, "ZoneID": "Europe\/Minsk", "offsetFromUTC": 180 }, { "City": "Moscow", "Description": "Moscow Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Europe\/Moscow", "offsetFromUTC": 180, "preferred": true }, { "City": "Simferopol", "Description": "Eastern European Time", "CountryCode": "RU", "Country": "Ukraine", "supportsDST": 0, "ZoneID": "Europe\/Simferopol", "offsetFromUTC": 180 }, { "City": "Volgograd", "Description": "Volgograd Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Europe\/Volgograd", "offsetFromUTC": 180 }, { "City": "Baghdad", "Description": "Arabia Time", "CountryCode": "IQ", "Country": "Iraq", "supportsDST": 0, "ZoneID": "Asia\/Baghdad", "offsetFromUTC": 180 }, { "City": "Addis Ababa", "Description": "Eastern African Time", "CountryCode": "ET", "Country": "Ethiopia", "supportsDST": 0, "ZoneID": "Africa\/Addis_Ababa", "offsetFromUTC": 180 }, { "City": "Mogadishu", "Description": "Eastern African Time", "CountryCode": "SO", "Country": "Somalia", "supportsDST": 0, "ZoneID": "Africa\/Mogadishu", "offsetFromUTC": 180 }, { "City": "Riyadh", "Description": "Arabia Time", "CountryCode": "SA", "Country": "Saudi Arabia", "supportsDST": 0, "ZoneID": "Asia\/Riyadh", "offsetFromUTC": 180 }, { "City": "Asmara", "Description": "Eastern African Time", "CountryCode": "ER", "Country": "Eritrea", "supportsDST": 0, "ZoneID": "Africa\/Asmara", "offsetFromUTC": 180 }, { "City": "Antananarivo", "Description": "Eastern African Time", "CountryCode": "MG", "Country": "Madagascar", "supportsDST": 0, "ZoneID": "Indian\/Antananarivo", "offsetFromUTC": 180 }, { "City": "Kampala", "Description": "Eastern African Time", "CountryCode": "UG", "Country": "Uganda", "supportsDST": 0, "ZoneID": "Africa\/Kampala", "offsetFromUTC": 180 }, { "City": "Dar es Salaam", "Description": "Eastern African Time", "CountryCode": "TZ", "Country": "Tanzania", "supportsDST": 0, "ZoneID": "Africa\/Dar_es_Salaam", "offsetFromUTC": 180 }, { "City": "Nairobi", "Description": "Eastern African Time", "CountryCode": "KE", "Country": "Kenya", "supportsDST": 0, "ZoneID": "Africa\/Nairobi", "offsetFromUTC": 180 }, { "City": "Kuwait City", "Description": "Arabia Time", "CountryCode": "KW", "Country": "Kuwait", "supportsDST": 0, "ZoneID": "Asia\/Kuwait", "offsetFromUTC": 180 }, { "City": "Khartoum", "Description": "Eastern African Time", "CountryCode": "SD", "Country": "Sudan", "supportsDST": 0, "ZoneID": "Africa\/Khartoum", "offsetFromUTC": 180 }, { "City": "Aden", "Description": "Arabia Time", "CountryCode": "YE", "Country": "Yemen", "supportsDST": 0, "ZoneID": "Asia\/Aden", "offsetFromUTC": 180 }, { "City": "", "Description": "Eastern African Time", "CountryCode": "YT", "Country": "Mayotte", "supportsDST": 0, "ZoneID": "Indian\/Mayotte", "offsetFromUTC": 180 }, { "City": "Doha", "Description": "Arabia Time", "CountryCode": "QA", "Country": "Qatar", "supportsDST": 0, "ZoneID": "Asia\/Qatar", "offsetFromUTC": 180 }, { "City": "Tehran", "Description": "Iran Time", "CountryCode": "IR", "Country": "Iran", "supportsDST": 1, "ZoneID": "Asia\/Tehran", "offsetFromUTC": 210, "preferred": true }, { "City": "Samara", "Description": "Samara Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Europe\/Samara", "offsetFromUTC": 240, "preferred": true }, { "City": "Tbilisi", "Description": "Georgia Time", "CountryCode": "GE", "Country": "Georgia", "supportsDST": 0, "ZoneID": "Asia\/Tbilisi", "offsetFromUTC": 240 }, { "City": "Muscat", "Description": "Gulf Time", "CountryCode": "OM", "Country": "Oman", "supportsDST": 0, "ZoneID": "Asia\/Muscat", "offsetFromUTC": 240 }, { "City": "Port Louis", "Description": "Mauritius Time", "CountryCode": "MU", "Country": "Mauritius", "supportsDST": 0, "ZoneID": "Indian\/Mauritius", "offsetFromUTC": 240 }, { "City": "Dubai", "Description": "Gulf Time", "CountryCode": "AE", "Country": "United Arab Emirates", "supportsDST": 0, "ZoneID": "Asia\/Dubai", "offsetFromUTC": 240 }, { "City": "Yerevan", "Description": "Armenia Time", "CountryCode": "AM", "Country": "Armenia", "supportsDST": 0, "ZoneID": "Asia\/Yerevan", "offsetFromUTC": 240 }, { "City": "Baku", "Description": "Azerbaijan Time", "CountryCode": "AZ", "Country": "Azerbaijan", "supportsDST": 0, "ZoneID": "Asia\/Baku", "offsetFromUTC": 240 }, { "City": "Kabul", "Description": "Afghanistan Time", "CountryCode": "AF", "Country": "Afghanistan", "supportsDST": 0, "ZoneID": "Asia\/Kabul", "offsetFromUTC": 270, "preferred": true }, { "City": "Yekaterinburg", "Description": "Yekaterinburg Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Yekaterinburg", "offsetFromUTC": 300 }, { "City": "Ashgabat", "Description": "Turkmenistan Time", "CountryCode": "TM", "Country": "Turkmenistan", "supportsDST": 0, "ZoneID": "Asia\/Ashgabat", "offsetFromUTC": 300 }, { "City": "Dushanbe", "Description": "Tajikistan Time", "CountryCode": "TJ", "Country": "Tajikistan", "supportsDST": 0, "ZoneID": "Asia\/Dushanbe", "offsetFromUTC": 300 }, { "City": "Karachi", "Description": "Pakistan Time", "CountryCode": "PK", "Country": "Pakistan", "supportsDST": 0, "ZoneID": "Asia\/Karachi", "offsetFromUTC": 300, "preferred": true }, { "City": "Samarkand", "Description": "Uzbekistan Time", "CountryCode": "UZ", "Country": "Uzbekistan", "supportsDST": 0, "ZoneID": "Asia\/Samarkand", "offsetFromUTC": 300 }, { "City": "Tashkent", "Description": "Uzbekistan Time", "CountryCode": "UZ", "Country": "Uzbekistan", "supportsDST": 0, "ZoneID": "Asia\/Tashkent", "offsetFromUTC": 300 }, { "City": "", "Description": "Maldives Time", "CountryCode": "MV", "Country": "Maldives", "supportsDST": 0, "ZoneID": "Indian\/Maldives", "offsetFromUTC": 300, "preferred": true }, { "City": "Aqtöbe", "Description": "Aqtöbe Time", "CountryCode": "KZ", "Country": "Kazakhstan", "supportsDST": 0, "ZoneID": "Asia\/Aqtobe", "offsetFromUTC": 300 }, { "City": "Colombo", "Description": "India Time", "CountryCode": "LK", "Country": "Sri Lanka", "supportsDST": 0, "ZoneID": "Asia\/Colombo", "offsetFromUTC": 330 }, { "City": "Kolkata", "Description": "India Time", "CountryCode": "IN", "Country": "India", "supportsDST": 0, "ZoneID": "Asia\/Kolkata", "offsetFromUTC": 330, "preferred": true }, { "City": "Dhaka", "Description": "Bangladesh Time", "CountryCode": "BD", "Country": "Bangladesh", "supportsDST": 0, "ZoneID": "Asia\/Dhaka", "offsetFromUTC": 360 }, { "City": "Thimphu", "Description": "Bhutan Time", "CountryCode": "BT", "Country": "Bhutan", "supportsDST": 0, "ZoneID": "Asia\/Thimphu", "offsetFromUTC": 360 }, { "City": "Omsk", "Description": "Omsk Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Omsk", "offsetFromUTC": 360 }, { "City": "Novosibirsk", "Description": "Novosibirsk Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Novosibirsk", "offsetFromUTC": 360, "preferred": true }, { "City": "Urumqi", "Description": "China Time", "CountryCode": "CN", "Country": "China", "supportsDST": 0, "ZoneID": "Asia\/Urumqi", "offsetFromUTC": 360 }, { "City": "Bishkek", "Description": "Kirgizstan Time", "CountryCode": "KG", "Country": "Kyrgyzstan", "supportsDST": 0, "ZoneID": "Asia\/Bishkek", "offsetFromUTC": 360 }, { "City": "Almaty", "Description": "Alma-Ata Time", "CountryCode": "KZ", "Country": "Kazakhstan", "supportsDST": 0, "ZoneID": "Asia\/Almaty", "offsetFromUTC": 360 }, { "City": "Rangoon", "Description": "Myanmar Time", "CountryCode": "MM", "Country": "Myanmar", "supportsDST": 0, "ZoneID": "Asia\/Rangoon", "offsetFromUTC": 390, "preferred": true }, { "City": "Krasnoyarsk", "Description": "Krasnoyarsk Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Krasnoyarsk", "offsetFromUTC": 420, "preferred": true }, { "City": "Ho Chi Minh", "Description": "Indochina Time", "CountryCode": "VN", "Country": "Vietnam", "supportsDST": 0, "ZoneID": "Asia\/Ho_Chi_Minh", "offsetFromUTC": 420 }, { "City": "Khovd", "Description": "Khovd Time", "CountryCode": "MN", "Country": "Mongolia", "supportsDST": 1, "ZoneID": "Asia\/Hovd", "offsetFromUTC": 420 }, { "City": "Christmas Island", "Description": "Christmas Island Time", "CountryCode": "CX", "Country": "Australia", "supportsDST": 0, "ZoneID": "Indian\/Christmas", "offsetFromUTC": 420, "preferred": true }, { "City": "Phnom Penh", "Description": "Indochina Time", "CountryCode": "KH", "Country": "Cambodia", "supportsDST": 0, "ZoneID": "Asia\/Phnom_Penh", "offsetFromUTC": 420 }, { "City": "Vientiane", "Description": "Indochina Time", "CountryCode": "LA", "Country": "Laos", "supportsDST": 0, "ZoneID": "Asia\/Vientiane", "offsetFromUTC": 420 }, { "City": "Bangkok", "Description": "Indochina Time", "CountryCode": "TH", "Country": "Thailand", "supportsDST": 0, "ZoneID": "Asia\/Bangkok", "offsetFromUTC": 420 }, { "City": "Jakarta", "Description": "West Indonesia Time", "CountryCode": "ID", "Country": "Indonesia", "supportsDST": 0, "ZoneID": "Asia\/Jakarta", "offsetFromUTC": 420 }, { "City": "Pontianak", "Description": "West Indonesia Time", "CountryCode": "ID", "Country": "Indonesia", "supportsDST": 0, "ZoneID": "Asia\/Pontianak", "offsetFromUTC": 420 }, { "City": "Irkutsk", "Description": "Irkutsk Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Irkutsk", "offsetFromUTC": 480 }, { "City": "", "Description": "Hong Kong Time", "CountryCode": "HK", "Country": "Hong Kong", "supportsDST": 0, "ZoneID": "Asia\/Hong_Kong", "offsetFromUTC": 480 }, { "City": "Manila", "Description": "Philippines Time", "CountryCode": "PH", "Country": "Philippines", "supportsDST": 0, "ZoneID": "Asia\/Manila", "offsetFromUTC": 480 }, { "City": "", "Description": "China Time", "CountryCode": "MO", "Country": "Macao", "supportsDST": 0, "ZoneID": "Asia\/Macau", "offsetFromUTC": 480 }, { "City": "Ulaanbaatar", "Description": "Ulaanbaatar Time", "CountryCode": "MN", "Country": "Mongolia", "supportsDST": 1, "ZoneID": "Asia\/Ulaanbaatar", "offsetFromUTC": 480 }, { "City": "Choibalsan", "Description": "Choibalsan Time", "CountryCode": "MN", "Country": "Mongolia", "supportsDST": 1, "ZoneID": "Asia\/Choibalsan", "offsetFromUTC": 480 }, { "City": "Kuala Lumpur", "Description": "Malaysia Time", "CountryCode": "MY", "Country": "Malaysia", "supportsDST": 0, "ZoneID": "Asia\/Kuala_Lumpur", "offsetFromUTC": 480 }, { "City": "Kuching", "Description": "Malaysia Time", "CountryCode": "MY", "Country": "Malaysia", "supportsDST": 0, "ZoneID": "Asia\/Kuching", "offsetFromUTC": 480 }, { "City": "Beijing", "Description": "China Time", "CountryCode": "CN", "Country": "China", "supportsDST": 0, "ZoneID": "Asia\/Shanghai", "offsetFromUTC": 480 }, { "City": "", "Description": "Singapore Time", "CountryCode": "SG", "Country": "Singapore", "supportsDST": 0, "ZoneID": "Asia\/Singapore", "offsetFromUTC": 480 }, { "City": "Taipei", "Description": "China Time", "CountryCode": "TW", "Country": "Taiwan", "supportsDST": 0, "ZoneID": "Asia\/Taipei", "offsetFromUTC": 480 }, { "City": "Perth", "Description": "Western Time (Australia)", "CountryCode": "AU", "Country": "Australia", "supportsDST": 0, "ZoneID": "Australia\/Perth", "offsetFromUTC": 480, "preferred": true }, { "City": "Makassar", "Description": "Central Indonesia Time", "CountryCode": "ID", "Country": "Indonesia", "supportsDST": 0, "ZoneID": "Asia\/Makassar", "offsetFromUTC": 480 }, { "City": "Pyongyang", "Description": "Korea Time", "CountryCode": "KP", "Country": "North Korea", "supportsDST": 0, "ZoneID": "Asia\/Pyongyang", "offsetFromUTC": 510 }, { "City": "Eucla", "Description": "Central Western Time (Australia)", "CountryCode": "AU", "Country": "Australia", "supportsDST": 0, "ZoneID": "Australia\/Eucla", "offsetFromUTC": 525, "preferred": true }, { "City": "Yakutsk", "Description": "Yakutsk Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Yakutsk", "offsetFromUTC": 540, "preferred": true }, { "City": "Dili", "Description": "Timor-Leste Time", "CountryCode": "TL", "Country": "Timor-Leste", "supportsDST": 0, "ZoneID": "Asia\/Dili", "offsetFromUTC": 540 }, { "City": "Tokyo", "Description": "Japan Time", "CountryCode": "JP", "Country": "Japan", "supportsDST": 0, "ZoneID": "Asia\/Tokyo", "offsetFromUTC": 540 }, { "City": "Palau", "Description": "Palau Time", "CountryCode": "PW", "Country": "Palau", "supportsDST": 0, "ZoneID": "Pacific\/Palau", "offsetFromUTC": 540 }, { "City": "Seoul", "Description": "Korea Time", "CountryCode": "KR", "Country": "South Korea", "supportsDST": 0, "ZoneID": "Asia\/Seoul", "offsetFromUTC": 540, "preferred": true }, { "City": "Jayapura", "Description": "East Indonesia Time", "CountryCode": "ID", "Country": "Indonesia", "supportsDST": 0, "ZoneID": "Asia\/Jayapura", "offsetFromUTC": 540 }, { "City": "Broken Hill", "Description": "Central Time (South Australia)", "CountryCode": "AU", "Country": "Australia", "supportsDST": 1, "ZoneID": "Australia\/Broken_Hill", "offsetFromUTC": 570 }, { "City": "Adelaide", "Description": "Central Time (South Australia)", "CountryCode": "AU", "Country": "Australia", "supportsDST": 1, "ZoneID": "Australia\/Adelaide", "offsetFromUTC": 570, "preferred": true }, { "City": "Darwin", "Description": "Central Time (Northern Territory)", "CountryCode": "AU", "Country": "Australia", "supportsDST": 0, "ZoneID": "Australia\/Darwin", "offsetFromUTC": 570 }, { "City": "Vladivostok", "Description": "Vladivostok Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Vladivostok", "offsetFromUTC": 600 }, { "City": "Magadan", "Description": "Magadan Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Magadan", "offsetFromUTC": 600, "preferred": true }, { "City": "Sakhalin", "Description": "Sakhalin Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Sakhalin", "offsetFromUTC": 600 }, { "City": "", "Description": "Chamorro Time", "CountryCode": "GU", "Country": "Guam", "supportsDST": 0, "ZoneID": "Pacific\/Guam", "offsetFromUTC": 600 }, { "City": "Port Moresby", "Description": "Papua New Guinea Time", "CountryCode": "PG", "Country": "Papua New Guinea", "supportsDST": 0, "ZoneID": "Pacific\/Port_Moresby", "offsetFromUTC": 600 }, { "City": "Hobart", "Description": "Eastern Time (Tasmania)", "CountryCode": "AU", "Country": "Australia", "supportsDST": 1, "ZoneID": "Australia\/Hobart", "offsetFromUTC": 600 }, { "City": "Melbourne", "Description": "Eastern Time (Victoria)", "CountryCode": "AU", "Country": "Australia", "supportsDST": 1, "ZoneID": "Australia\/Melbourne", "offsetFromUTC": 600 }, { "City": "Sydney", "Description": "Eastern Time (New South Wales)", "CountryCode": "AU", "Country": "Australia", "supportsDST": 1, "ZoneID": "Australia\/Sydney", "offsetFromUTC": 600, "preferred": true }, { "City": "Brisbane", "Description": "Eastern Time (Queensland)", "CountryCode": "AU", "Country": "Australia", "supportsDST": 0, "ZoneID": "Australia\/Brisbane", "offsetFromUTC": 600 }, { "City": "Lord Howe", "Description": "Lord Howe Time", "CountryCode": "AU", "Country": "Australia", "supportsDST": 1, "ZoneID": "Australia\/Lord_Howe", "offsetFromUTC": 630, "preferred": true }, { "City": "Guadalcanal", "Description": "Solomon Island Time", "CountryCode": "SB", "Country": "Solomon Islands", "supportsDST": 0, "ZoneID": "Pacific\/Guadalcanal", "offsetFromUTC": 660, "preferred": true }, { "City": "Nouméa", "Description": "New Caledonia Time", "CountryCode": "NC", "Country": "New Caledonia", "supportsDST": 0, "ZoneID": "Pacific\/Noumea", "offsetFromUTC": 660 }, { "City": "Kingston", "Description": "Norfolk Island Time", "CountryCode": "NF", "Country": "Australia", "supportsDST": 0, "ZoneID": "Pacific\/Norfolk", "offsetFromUTC": 660, "preferred": true }, { "City": "Kamchatka", "Description": "Petropavlovsk-Kamchatski Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Kamchatka", "offsetFromUTC": 720 }, { "City": "Anadyr", "Description": "Anadyr Time", "CountryCode": "RU", "Country": "Russia", "supportsDST": 0, "ZoneID": "Asia\/Anadyr", "offsetFromUTC": 720 }, { "City": "", "Description": "Marshall Islands Time", "CountryCode": "MH", "Country": "Marshall Islands", "supportsDST": 0, "ZoneID": "Pacific\/Kwajalein", "offsetFromUTC": 720 }, { "City": "", "Description": "Fiji Time", "CountryCode": "FJ", "Country": "Fiji", "supportsDST": 1, "ZoneID": "Pacific\/Fiji", "offsetFromUTC": 720, "preferred": true }, { "City": "Auckland", "Description": "New Zealand Time", "CountryCode": "NZ", "Country": "New Zealand", "supportsDST": 1, "ZoneID": "Pacific\/Auckland", "offsetFromUTC": 720, "preferred": true }, { "City": "Chatham Islands", "Description": "Chatham Time", "CountryCode": "NZ", "Country": "New Zealand", "supportsDST": 1, "ZoneID": "Pacific\/Chatham", "offsetFromUTC": 765, "preferred": true }, { "City": "Apia", "Description": "West Samoa Time", "CountryCode": "WS", "Country": "Samoa", "supportsDST": 1, "ZoneID": "Pacific\/Apia", "offsetFromUTC": 780, "preferred": true }, { "City": "", "Description": "Tonga Time", "CountryCode": "TO", "Country": "Tonga", "supportsDST": 0, "ZoneID": "Pacific\/Tongatapu", "offsetFromUTC": 780, "preferred": true }, { "City": "Kiritimati", "Description": "Christmas Island Time", "CountryCode": "KI", "Country": "Kiribati", "supportsDST": 0, "ZoneID": "Pacific\/Kiritimati", "offsetFromUTC": 840, "preferred": true } ],
                "mmcInfo": { "mccInfo": [ { "offsetFromUTC": 120, "Country": "Greece", "mcc": 202, "supportsDST": 1, "CountryCode": "GR" }, { "offsetFromUTC": 60, "Country": "Netherlands", "mcc": 204, "supportsDST": 1, "CountryCode": "NL" }, { "offsetFromUTC": 60, "Country": "Belgium", "mcc": 206, "supportsDST": 1, "CountryCode": "BE" }, { "offsetFromUTC": 60, "Country": "France", "mcc": 208, "supportsDST": 1, "CountryCode": "FR" }, { "offsetFromUTC": 60, "Country": "Monaco", "mcc": 212, "supportsDST": 1, "CountryCode": "MC" }, { "offsetFromUTC": 60, "Country": "Andorra", "mcc": 213, "supportsDST": 1, "CountryCode": "AD" }, { "CountryCode": "ES", "Country": "Spain", "mcc": 214, "supportsDST": 1, "ZoneID": "Europe\/Madrid", "offsetFromUTC": 60 }, { "offsetFromUTC": 60, "Country": "Hungary", "mcc": 216, "supportsDST": 1, "CountryCode": "HU" }, { "offsetFromUTC": 60, "Country": "Bosnia And Herzegovina", "mcc": 218, "supportsDST": 1, "CountryCode": "BA" }, { "offsetFromUTC": 60, "Country": "Croatia", "mcc": 219, "supportsDST": 1, "CountryCode": "HR" }, { "offsetFromUTC": 60, "Country": "Yugoslavia", "mcc": 220, "supportsDST": 1, "CountryCode": "MK" }, { "offsetFromUTC": 60, "Country": "Italy", "mcc": 222, "supportsDST": 1, "CountryCode": "IT" }, { "offsetFromUTC": 60, "Country": "Vatican", "mcc": 225, "supportsDST": 1, "CountryCode": "VA" }, { "offsetFromUTC": 120, "Country": "Romania", "mcc": 226, "supportsDST": 1, "CountryCode": "RO" }, { "offsetFromUTC": 60, "Country": "Switzerland", "mcc": 228, "supportsDST": 1, "CountryCode": "CH" }, { "offsetFromUTC": 60, "Country": "Czech Republic", "mcc": 230, "supportsDST": 1, "CountryCode": "CZ" }, { "offsetFromUTC": 60, "Country": "Slovakia", "mcc": 231, "supportsDST": 1, "CountryCode": "SK" }, { "offsetFromUTC": 60, "Country": "Austria", "mcc": 232, "supportsDST": 1, "CountryCode": "AT" }, { "offsetFromUTC": 0, "Country": "United Kingdom", "mcc": 234, "supportsDST": 1, "CountryCode": "GB" }, { "offsetFromUTC": 0, "Country": "United Kingdom", "mcc": 235, "supportsDST": 1, "CountryCode": "GB" }, { "offsetFromUTC": 60, "Country": "Denmark", "mcc": 238, "supportsDST": 1, "CountryCode": "DK" }, { "offsetFromUTC": 60, "Country": "Sweden", "mcc": 240, "supportsDST": 1, "CountryCode": "SE" }, { "offsetFromUTC": 60, "Country": "Norway", "mcc": 242, "supportsDST": 1, "CountryCode": "NO" }, { "offsetFromUTC": 120, "Country": "Finland", "mcc": 244, "supportsDST": 1, "CountryCode": "FI" }, { "offsetFromUTC": 120, "Country": "Lithuania", "mcc": 246, "supportsDST": 1, "CountryCode": "LT" }, { "offsetFromUTC": 120, "Country": "Latvia", "mcc": 247, "supportsDST": 1, "CountryCode": "LV" }, { "offsetFromUTC": 120, "Country": "Estonia", "mcc": 248, "supportsDST": 1, "CountryCode": "EE" }, { "offsetFromUTC": 240, "Country": "Russian Federation", "mcc": 250, "supportsDST": 0, "CountryCode": "RU" }, { "offsetFromUTC": 120, "Country": "Ukraine", "mcc": 255, "supportsDST": 1, "CountryCode": "UA" }, { "offsetFromUTC": 180, "Country": "Belarus", "mcc": 257, "supportsDST": 0, "CountryCode": "BY" }, { "offsetFromUTC": 120, "Country": "Moldova", "mcc": 259, "supportsDST": 1, "CountryCode": "MD" }, { "offsetFromUTC": 60, "Country": "Poland", "mcc": 260, "supportsDST": 1, "CountryCode": "PL" }, { "offsetFromUTC": 60, "Country": "Germany", "mcc": 262, "supportsDST": 1, "CountryCode": "DE" }, { "offsetFromUTC": 60, "Country": "Gibraltar", "mcc": 266, "supportsDST": 1, "CountryCode": "GI" }, { "offsetFromUTC": 0, "Country": "Portugal", "mcc": 268, "supportsDST": 1, "CountryCode": "PT" }, { "offsetFromUTC": 60, "Country": "Luxembourg", "mcc": 270, "supportsDST": 1, "CountryCode": "LU" }, { "offsetFromUTC": 0, "Country": "Ireland", "mcc": 272, "supportsDST": 1, "CountryCode": "IE" }, { "offsetFromUTC": 0, "Country": "Iceland", "mcc": 274, "supportsDST": 0, "CountryCode": "IS" }, { "offsetFromUTC": 60, "Country": "Albania", "mcc": 276, "supportsDST": 1, "CountryCode": "AL" }, { "offsetFromUTC": 60, "Country": "Malta", "mcc": 278, "supportsDST": 1, "CountryCode": "MT" }, { "offsetFromUTC": 120, "Country": "Cyprus", "mcc": 280, "supportsDST": 1, "CountryCode": "CY" }, { "offsetFromUTC": 240, "Country": "Georgia", "mcc": 282, "supportsDST": 0, "CountryCode": "GE" }, { "offsetFromUTC": 240, "Country": "Armenia", "mcc": 283, "supportsDST": 0, "CountryCode": "AM" }, { "offsetFromUTC": 120, "Country": "Bulgaria", "mcc": 284, "supportsDST": 1, "CountryCode": "BG" }, { "offsetFromUTC": 120, "Country": "Turkey", "mcc": 286, "supportsDST": 1, "CountryCode": "TR" }, { "offsetFromUTC": 0, "Country": "Faroe Islands", "mcc": 288, "supportsDST": 1, "CountryCode": "FO" }, { "offsetFromUTC": -180, "Country": "Greenland", "mcc": 290, "supportsDST": 1, "CountryCode": "GL" }, { "offsetFromUTC": 60, "Country": "San Marino", "mcc": 292, "supportsDST": 1, "CountryCode": "SM" }, { "offsetFromUTC": 60, "Country": "Slovenia", "mcc": 293, "supportsDST": 1, "CountryCode": "SI" }, { "offsetFromUTC": 60, "Country": "Macedonia,  The Former Yugoslav Republic Of", "mcc": 294, "supportsDST": 1, "CountryCode": "MK" }, { "offsetFromUTC": 60, "Country": "Liechtenstein", "mcc": 295, "supportsDST": 1, "CountryCode": "LI" }, { "offsetFromUTC": 60, "Country": "Montenegro", "mcc": 297, "supportsDST": 1, "CountryCode": "ME" }, { "offsetFromUTC": -300, "Country": "Canada", "mcc": 302, "supportsDST": 1, "CountryCode": "CA" }, { "offsetFromUTC": -180, "Country": "St. Pierre And Miquelon", "mcc": 308, "supportsDST": 1, "CountryCode": "PM" }, { "offsetFromUTC": -300, "Country": "United States", "mcc": 310, "supportsDST": 1, "CountryCode": "US" }, { "offsetFromUTC": -300, "Country": "United States", "mcc": 311, "supportsDST": 1, "CountryCode": "US" }, { "offsetFromUTC": -300, "Country": "United States", "mcc": 312, "supportsDST": 1, "CountryCode": "US" }, { "offsetFromUTC": -300, "Country": "United States", "mcc": 313, "supportsDST": 1, "CountryCode": "US" }, { "offsetFromUTC": -300, "Country": "United States", "mcc": 314, "supportsDST": 1, "CountryCode": "US" }, { "offsetFromUTC": -300, "Country": "United States", "mcc": 315, "supportsDST": 1, "CountryCode": "US" }, { "offsetFromUTC": -300, "Country": "United States", "mcc": 316, "supportsDST": 1, "CountryCode": "US" }, { "offsetFromUTC": -240, "Country": "Puerto Rico", "mcc": 330, "supportsDST": 0, "CountryCode": "PR" }, { "offsetFromUTC": -240, "Country": "US Virgin Islands", "mcc": 332, "supportsDST": 0, "CountryCode": "VI" }, { "offsetFromUTC": -360, "Country": "Mexico", "mcc": 334, "supportsDST": 1, "CountryCode": "MX" }, { "offsetFromUTC": -300, "Country": "Jamaica", "mcc": 338, "supportsDST": 0, "CountryCode": "JM" }, { "offsetFromUTC": -240, "Country": "Guadeloupe", "mcc": 340, "supportsDST": 0, "CountryCode": "GP" }, { "offsetFromUTC": -240, "Country": "Martinique", "mcc": 340, "supportsDST": 0, "CountryCode": "MQ" }, { "offsetFromUTC": -240, "Country": "Barbados", "mcc": 342, "supportsDST": 0, "CountryCode": "BB" }, { "offsetFromUTC": -240, "Country": "Antigua And Barbuda", "mcc": 344, "supportsDST": 0, "CountryCode": "AG" }, { "offsetFromUTC": -300, "Country": "Cayman Islands", "mcc": 346, "supportsDST": 0, "CountryCode": "KY" }, { "offsetFromUTC": -240, "Country": "British Virgin Islands", "mcc": 348, "supportsDST": 0, "CountryCode": "VG" }, { "offsetFromUTC": -240, "Country": "Bermuda", "mcc": 350, "supportsDST": 1, "CountryCode": "BM" }, { "offsetFromUTC": -240, "Country": "Grenada", "mcc": 352, "supportsDST": 0, "CountryCode": "GD" }, { "offsetFromUTC": -240, "Country": "Montserrat", "mcc": 354, "supportsDST": 0, "CountryCode": "MS" }, { "offsetFromUTC": -240, "Country": "St. Kitts And Nevis", "mcc": 356, "supportsDST": 0, "CountryCode": "KN" }, { "offsetFromUTC": -240, "Country": "St. Lucia", "mcc": 358, "supportsDST": 0, "CountryCode": "LC" }, { "offsetFromUTC": -240, "Country": "St. Vincent And The Grenadines", "mcc": 360, "supportsDST": 0, "CountryCode": "VC" }, { "offsetFromUTC": -240, "Country": "Netherlands Antilles", "mcc": 362, "supportsDST": 0, "CountryCode": "AN" }, { "offsetFromUTC": -240, "Country": "Aruba", "mcc": 363, "supportsDST": 0, "CountryCode": "AW" }, { "offsetFromUTC": -300, "Country": "Bahamas", "mcc": 364, "supportsDST": 1, "CountryCode": "BS" }, { "offsetFromUTC": -240, "Country": "Anguilla", "mcc": 365, "supportsDST": 0, "CountryCode": "AI" }, { "offsetFromUTC": -240, "Country": "Dominica", "mcc": 366, "supportsDST": 0, "CountryCode": "DM" }, { "offsetFromUTC": -300, "Country": "Cuba", "mcc": 368, "supportsDST": 1, "CountryCode": "CU" }, { "offsetFromUTC": -240, "Country": "Dominican Republic", "mcc": 370, "supportsDST": 0, "CountryCode": "DO" }, { "offsetFromUTC": -300, "Country": "Haiti", "mcc": 372, "supportsDST": 0, "CountryCode": "HT" }, { "offsetFromUTC": -240, "Country": "Trinidad And Tobago", "mcc": 374, "supportsDST": 0, "CountryCode": "TT" }, { "offsetFromUTC": -300, "Country": "Turks And Caicos Islands", "mcc": 376, "supportsDST": 1, "CountryCode": "TC" }, { "offsetFromUTC": 240, "Country": "Azerbaijan", "mcc": 400, "supportsDST": 1, "CountryCode": "AZ" }, { "offsetFromUTC": 300, "Country": "Kazakhstan", "mcc": 401, "supportsDST": 0, "CountryCode": "KZ" }, { "offsetFromUTC": 360, "Country": "Bhutan", "mcc": 402, "supportsDST": 0, "CountryCode": "BT" }, { "offsetFromUTC": 330, "Country": "India", "mcc": 404, "supportsDST": 0, "CountryCode": "IN" }, { "offsetFromUTC": 330, "Country": "India", "mcc": 405, "supportsDST": 0, "CountryCode": "IN" }, { "offsetFromUTC": 300, "Country": "Pakistan", "mcc": 410, "supportsDST": 0, "CountryCode": "PK" }, { "offsetFromUTC": 270, "Country": "Afghanistan", "mcc": 412, "supportsDST": 0, "CountryCode": "AF" }, { "offsetFromUTC": 330, "Country": "Sri Lanka", "mcc": 413, "supportsDST": 0, "CountryCode": "LK" }, { "offsetFromUTC": 390, "Country": "Myanmar", "mcc": 414, "supportsDST": 0, "CountryCode": "MM" }, { "offsetFromUTC": 120, "Country": "Lebanon", "mcc": 415, "supportsDST": 1, "CountryCode": "LB" }, { "offsetFromUTC": 180, "Country": "Jordan", "mcc": 416, "supportsDST": 0, "CountryCode": "JO" }, { "offsetFromUTC": 120, "Country": "Syrian Arab Republic", "mcc": 417, "supportsDST": 1, "CountryCode": "SY" }, { "offsetFromUTC": 180, "Country": "Iraq", "mcc": 418, "supportsDST": 0, "CountryCode": "IQ" }, { "offsetFromUTC": 180, "Country": "Kuwait", "mcc": 419, "supportsDST": 0, "CountryCode": "KW" }, { "offsetFromUTC": 180, "Country": "Saudi Arabia", "mcc": 420, "supportsDST": 0, "CountryCode": "SA" }, { "offsetFromUTC": 180, "Country": "Yemen", "mcc": 421, "supportsDST": 0, "CountryCode": "YE" }, { "offsetFromUTC": 240, "Country": "Oman", "mcc": 422, "supportsDST": 0, "CountryCode": "OM" }, { "offsetFromUTC": 240, "Country": "United Arab Emirates", "mcc": 424, "supportsDST": 0, "CountryCode": "AE" }, { "offsetFromUTC": 120, "Country": "Israel", "mcc": 425, "supportsDST": 1, "CountryCode": "IL" }, { "offsetFromUTC": 180, "Country": "Bahrain", "mcc": 426, "supportsDST": 0, "CountryCode": "BH" }, { "offsetFromUTC": 180, "Country": "Qatar", "mcc": 427, "supportsDST": 0, "CountryCode": "QA" }, { "offsetFromUTC": 480, "Country": "Mongolia", "mcc": 428, "supportsDST": 0, "CountryCode": "MN" }, { "offsetFromUTC": 345, "Country": "Nepal", "mcc": 429, "supportsDST": 0, "CountryCode": "NP" }, { "offsetFromUTC": 240, "Country": "United Arab Emirates", "mcc": 430, "supportsDST": 0, "CountryCode": "AE" }, { "offsetFromUTC": 240, "Country": "United Arab Emirates", "mcc": 431, "supportsDST": 0, "CountryCode": "AE" }, { "offsetFromUTC": 210, "Country": "Iran", "mcc": 432, "supportsDST": 1, "CountryCode": "IR" }, { "offsetFromUTC": 300, "Country": "Uzbekistan", "mcc": 434, "supportsDST": 0, "CountryCode": "UZ" }, { "offsetFromUTC": 300, "Country": "Tajikistan", "mcc": 436, "supportsDST": 0, "CountryCode": "TJ" }, { "offsetFromUTC": 360, "Country": "Kyrgyzstan", "mcc": 437, "supportsDST": 0, "CountryCode": "KG" }, { "offsetFromUTC": 300, "Country": "Turkmenistan", "mcc": 438, "supportsDST": 0, "CountryCode": "TM" }, { "offsetFromUTC": 540, "Country": "Japan", "mcc": 440, "supportsDST": 0, "CountryCode": "JP" }, { "offsetFromUTC": 540, "Country": "Japan", "mcc": 441, "supportsDST": 0, "CountryCode": "JP" }, { "offsetFromUTC": 540, "Country": "South Korea", "mcc": 450, "supportsDST": 0, "CountryCode": "KR" }, { "offsetFromUTC": 420, "Country": "VietNam", "mcc": 452, "supportsDST": 0, "CountryCode": "VN" }, { "offsetFromUTC": 480, "Country": "Hong Kong", "mcc": 454, "supportsDST": 0, "CountryCode": "HK" }, { "offsetFromUTC": 480, "Country": "China", "mcc": 455, "supportsDST": 0, "CountryCode": "CN" }, { "offsetFromUTC": 420, "Country": "Cambodia", "mcc": 456, "supportsDST": 0, "CountryCode": "KH" }, { "offsetFromUTC": 420, "Country": "Laos", "mcc": 457, "supportsDST": 0, "CountryCode": "LA" }, { "offsetFromUTC": 480, "Country": "China", "mcc": 460, "supportsDST": 0, "CountryCode": "CN" }, { "offsetFromUTC": 480, "Country": "China", "mcc": 461, "supportsDST": 0, "CountryCode": "CN" }, { "offsetFromUTC": 480, "Country": "Taiwan", "mcc": 466, "supportsDST": 0, "CountryCode": "TW" }, { "offsetFromUTC": 540, "Country": "North Korea", "mcc": 467, "supportsDST": 0, "CountryCode": "KP" }, { "offsetFromUTC": 360, "Country": "Bangladesh", "mcc": 470, "supportsDST": 0, "CountryCode": "BD" }, { "offsetFromUTC": 300, "Country": "Maldives", "mcc": 472, "supportsDST": 0, "CountryCode": "MV" }, { "offsetFromUTC": 480, "Country": "Malaysia", "mcc": 502, "supportsDST": 0, "CountryCode": "MY" }, { "offsetFromUTC": 600, "Country": "Australia", "mcc": 505, "supportsDST": 1, "CountryCode": "AU" }, { "offsetFromUTC": 420, "Country": "Indonesia", "mcc": 510, "supportsDST": 0, "CountryCode": "ID" }, { "offsetFromUTC": 540, "Country": "East Timor", "mcc": 514, "supportsDST": 0, "CountryCode": "TL" }, { "offsetFromUTC": 480, "Country": "Philippines", "mcc": 515, "supportsDST": 0, "CountryCode": "PH" }, { "offsetFromUTC": 420, "Country": "Thailand", "mcc": 520, "supportsDST": 0, "CountryCode": "TH" }, { "offsetFromUTC": 480, "Country": "Singapore", "mcc": 525, "supportsDST": 0, "CountryCode": "SG" }, { "offsetFromUTC": 480, "Country": "Brunei Darussalam", "mcc": 528, "supportsDST": 0, "CountryCode": "BN" }, { "offsetFromUTC": 720, "Country": "New Zealand", "mcc": 530, "supportsDST": 1, "CountryCode": "NZ" }, { "offsetFromUTC": 660, "Country": "Northern Mariana Islands", "mcc": 534, "supportsDST": 0, "CountryCode": "MP" }, { "offsetFromUTC": 600, "Country": "Guam", "mcc": 535, "supportsDST": 0, "CountryCode": "GU" }, { "offsetFromUTC": 720, "Country": "Nauru", "mcc": 536, "supportsDST": 0, "CountryCode": "NR" }, { "offsetFromUTC": 600, "Country": "Papua New Guinea", "mcc": 537, "supportsDST": 0, "CountryCode": "PG" }, { "offsetFromUTC": 780, "Country": "Tonga", "mcc": 539, "supportsDST": 0, "CountryCode": "TO" }, { "offsetFromUTC": 660, "Country": "Solomon Islands", "mcc": 540, "supportsDST": 0, "CountryCode": "SB" }, { "offsetFromUTC": 660, "Country": "Vanuatu", "mcc": 541, "supportsDST": 0, "CountryCode": "VU" }, { "offsetFromUTC": 720, "Country": "Fiji", "mcc": 542, "supportsDST": 1, "CountryCode": "FJ" }, { "offsetFromUTC": 720, "Country": "Wallis and Futuna Islands", "mcc": 543, "supportsDST": 0, "CountryCode": "WF" }, { "offsetFromUTC": 660, "Country": "American Samoa", "mcc": 544, "supportsDST": 0, "CountryCode": "AS" }, { "offsetFromUTC": 840, "Country": "Kiribati", "mcc": 545, "supportsDST": 0, "CountryCode": "KI" }, { "offsetFromUTC": 660, "Country": "New Caledonia", "mcc": 546, "supportsDST": 0, "CountryCode": "NC" }, { "offsetFromUTC": -540, "Country": "French Polynesia", "mcc": 547, "supportsDST": 0, "CountryCode": "PF" }, { "offsetFromUTC": -600, "Country": "Cook Islands", "mcc": 548, "supportsDST": 0, "CountryCode": "CK" }, { "offsetFromUTC": 780, "Country": "Samoa", "mcc": 549, "supportsDST": 1, "CountryCode": "WS" }, { "offsetFromUTC": 660, "Country": "Micronesia", "mcc": 550, "supportsDST": 0, "CountryCode": "FM" }, { "offsetFromUTC": 720, "Country": "Marshall Islands", "mcc": 551, "supportsDST": 0, "CountryCode": "MH" }, { "offsetFromUTC": 540, "Country": "Palau", "mcc": 552, "supportsDST": 0, "CountryCode": "PW" }, { "offsetFromUTC": 720, "Country": "Tuvalu", "mcc": 553, "supportsDST": 0, "CountryCode": "TV" }, { "offsetFromUTC": -660, "Country": "Niue", "mcc": 555, "supportsDST": 0, "CountryCode": "NU" }, { "offsetFromUTC": 120, "Country": "Egypt", "mcc": 602, "supportsDST": 0, "CountryCode": "EG" }, { "offsetFromUTC": 60, "Country": "Algeria", "mcc": 603, "supportsDST": 0, "CountryCode": "DZ" }, { "offsetFromUTC": 0, "Country": "Morocco", "mcc": 604, "supportsDST": 1, "CountryCode": "MA" }, { "offsetFromUTC": 60, "Country": "Tunisia", "mcc": 605, "supportsDST": 0, "CountryCode": "TN" }, { "offsetFromUTC": 60, "Country": "Libya", "mcc": 606, "supportsDST": 1, "CountryCode": "LY" }, { "offsetFromUTC": 0, "Country": "Gambia", "mcc": 607, "supportsDST": 0, "CountryCode": "GM" }, { "offsetFromUTC": 0, "Country": "Senegal", "mcc": 608, "supportsDST": 0, "CountryCode": "SN" }, { "offsetFromUTC": 0, "Country": "Mauritania", "mcc": 609, "supportsDST": 0, "CountryCode": "MR" }, { "offsetFromUTC": 0, "Country": "Mali", "mcc": 610, "supportsDST": 0, "CountryCode": "ML" }, { "offsetFromUTC": 0, "Country": "Guinea", "mcc": 611, "supportsDST": 0, "CountryCode": "GN" }, { "offsetFromUTC": 0, "Country": "Ivory Coast", "mcc": 612, "supportsDST": 0, "CountryCode": "CI" }, { "offsetFromUTC": 0, "Country": "Burkina Faso", "mcc": 613, "supportsDST": 0, "CountryCode": "BF" }, { "offsetFromUTC": 60, "Country": "Niger", "mcc": 614, "supportsDST": 0, "CountryCode": "NE" }, { "offsetFromUTC": 0, "Country": "Togo", "mcc": 615, "supportsDST": 0, "CountryCode": "TG" }, { "offsetFromUTC": 60, "Country": "Benin", "mcc": 616, "supportsDST": 0, "CountryCode": "BJ" }, { "offsetFromUTC": 240, "Country": "Mauritius", "mcc": 617, "supportsDST": 0, "CountryCode": "MU" }, { "offsetFromUTC": 0, "Country": "Liberia", "mcc": 618, "supportsDST": 0, "CountryCode": "LR" }, { "offsetFromUTC": 0, "Country": "Sierra Leone", "mcc": 619, "supportsDST": 0, "CountryCode": "SL" }, { "offsetFromUTC": 0, "Country": "Ghana", "mcc": 620, "supportsDST": 0, "CountryCode": "GH" }, { "offsetFromUTC": 60, "Country": "Nigeria", "mcc": 621, "supportsDST": 0, "CountryCode": "NG" }, { "offsetFromUTC": 60, "Country": "Chad", "mcc": 622, "supportsDST": 0, "CountryCode": "TD" }, { "offsetFromUTC": 60, "Country": "Central African Republic", "mcc": 623, "supportsDST": 0, "CountryCode": "CF" }, { "offsetFromUTC": 60, "Country": "Cameroon", "mcc": 624, "supportsDST": 0, "CountryCode": "CM" }, { "offsetFromUTC": -60, "Country": "Cape Verde", "mcc": 625, "supportsDST": 0, "CountryCode": "CV" }, { "offsetFromUTC": 0, "Country": "Sao Tome And Principe", "mcc": 626, "supportsDST": 0, "CountryCode": "ST" }, { "offsetFromUTC": 60, "Country": "Equatorial Guinea", "mcc": 627, "supportsDST": 0, "CountryCode": "GQ" }, { "offsetFromUTC": 60, "Country": "Gabon", "mcc": 628, "supportsDST": 0, "CountryCode": "GA" }, { "offsetFromUTC": 60, "Country": "Congo", "mcc": 629, "supportsDST": 0, "CountryCode": "CG" }, { "offsetFromUTC": 60, "Country": "Democratic Republic Of The Congo", "mcc": 630, "supportsDST": 0, "CountryCode": "CD" }, { "offsetFromUTC": 60, "Country": "Angola", "mcc": 631, "supportsDST": 0, "CountryCode": "AO" }, { "offsetFromUTC": 0, "Country": "Guinea-Bisseu", "mcc": 632, "supportsDST": 0, "CountryCode": "GW" }, { "offsetFromUTC": 240, "Country": "Seychelles", "mcc": 633, "supportsDST": 0, "CountryCode": "SC" }, { "offsetFromUTC": 180, "Country": "Sudan", "mcc": 634, "supportsDST": 0, "CountryCode": "SD" }, { "offsetFromUTC": 120, "Country": "Rwanda", "mcc": 635, "supportsDST": 0, "CountryCode": "RW" }, { "offsetFromUTC": 180, "Country": "Ethiopia", "mcc": 636, "supportsDST": 0, "CountryCode": "ET" }, { "offsetFromUTC": 180, "Country": "Somalia", "mcc": 637, "supportsDST": 0, "CountryCode": "SO" }, { "offsetFromUTC": 180, "Country": "Djibouti", "mcc": 638, "supportsDST": 0, "CountryCode": "DJ" }, { "offsetFromUTC": 180, "Country": "Kenya", "mcc": 639, "supportsDST": 0, "CountryCode": "KE" }, { "offsetFromUTC": 180, "Country": "Tanzania", "mcc": 640, "supportsDST": 0, "CountryCode": "TZ" }, { "offsetFromUTC": 180, "Country": "Uganda", "mcc": 641, "supportsDST": 0, "CountryCode": "UG" }, { "offsetFromUTC": 120, "Country": "Burundi", "mcc": 642, "supportsDST": 0, "CountryCode": "BI" }, { "offsetFromUTC": 120, "Country": "Mozambique", "mcc": 643, "supportsDST": 0, "CountryCode": "MZ" }, { "offsetFromUTC": 120, "Country": "Zambia", "mcc": 645, "supportsDST": 0, "CountryCode": "ZM" }, { "offsetFromUTC": 180, "Country": "Madagascar", "mcc": 646, "supportsDST": 0, "CountryCode": "MG" }, { "offsetFromUTC": 240, "Country": "Reunion", "mcc": 647, "supportsDST": 0, "CountryCode": "RE" }, { "offsetFromUTC": 120, "Country": "Zimbabwe", "mcc": 648, "supportsDST": 0, "CountryCode": "ZW" }, { "offsetFromUTC": 60, "Country": "Namibia", "mcc": 649, "supportsDST": 1, "CountryCode": "NA" }, { "offsetFromUTC": 120, "Country": "Malawi", "mcc": 650, "supportsDST": 0, "CountryCode": "MW" }, { "offsetFromUTC": 120, "Country": "Lesotho", "mcc": 651, "supportsDST": 0, "CountryCode": "LS" }, { "offsetFromUTC": 120, "Country": "Botswana", "mcc": 652, "supportsDST": 0, "CountryCode": "BW" }, { "offsetFromUTC": 120, "Country": "Swaziland", "mcc": 653, "supportsDST": 0, "CountryCode": "SZ" }, { "offsetFromUTC": 180, "Country": "Comoros", "mcc": 654, "supportsDST": 0, "CountryCode": "KM" }, { "offsetFromUTC": 120, "Country": "South Africa", "mcc": 655, "supportsDST": 0, "CountryCode": "ZA" }, { "offsetFromUTC": 180, "Country": "Eritrea", "mcc": 657, "supportsDST": 0, "CountryCode": "ER" }, { "offsetFromUTC": 180, "Country": "South Sudan", "mcc": 659, "supportsDST": 0, "CountryCode": "SS" }, { "offsetFromUTC": -360, "Country": "Belize", "mcc": 702, "supportsDST": 0, "CountryCode": "BZ" }, { "offsetFromUTC": -360, "Country": "Guatemala", "mcc": 704, "supportsDST": 0, "CountryCode": "GT" }, { "offsetFromUTC": -360, "Country": "El Salvador", "mcc": 706, "supportsDST": 0, "CountryCode": "SV" }, { "offsetFromUTC": -360, "Country": "Honduras", "mcc": 708, "supportsDST": 0, "CountryCode": "HN" }, { "offsetFromUTC": -360, "Country": "Nicaragua", "mcc": 710, "supportsDST": 0, "CountryCode": "NI" }, { "offsetFromUTC": -360, "Country": "Costa Rica", "mcc": 712, "supportsDST": 0, "CountryCode": "CR" }, { "offsetFromUTC": -300, "Country": "Panama", "mcc": 714, "supportsDST": 0, "CountryCode": "PA" }, { "offsetFromUTC": -300, "Country": "Peru", "mcc": 716, "supportsDST": 0, "CountryCode": "PE" }, { "offsetFromUTC": -180, "Country": "Argentina", "mcc": 722, "supportsDST": 0, "CountryCode": "AR" }, { "offsetFromUTC": -240, "Country": "Brazil", "mcc": 724, "supportsDST": 1, "CountryCode": "BR" }, { "offsetFromUTC": -240, "Country": "Chile", "mcc": 730, "supportsDST": 1, "CountryCode": "CL" }, { "offsetFromUTC": -300, "Country": "Colombia", "mcc": 732, "supportsDST": 0, "CountryCode": "CO" }, { "offsetFromUTC": -270, "Country": "Venezuela", "mcc": 734, "supportsDST": 0, "CountryCode": "VE" }, { "offsetFromUTC": -240, "Country": "Bolivia", "mcc": 736, "supportsDST": 0, "CountryCode": "BO" }, { "offsetFromUTC": -240, "Country": "Guyana", "mcc": 738, "supportsDST": 0, "CountryCode": "GY" }, { "offsetFromUTC": -300, "Country": "Ecuador", "mcc": 740, "supportsDST": 0, "CountryCode": "EC" }, { "offsetFromUTC": -180, "Country": "French Guiana", "mcc": 742, "supportsDST": 0, "CountryCode": "GF" }, { "offsetFromUTC": -240, "Country": "Paraguay", "mcc": 744, "supportsDST": 1, "CountryCode": "PY" }, { "offsetFromUTC": -180, "Country": "Suriname", "mcc": 746, "supportsDST": 0, "CountryCode": "SR" }, { "offsetFromUTC": -180, "Country": "Uruguay", "mcc": 748, "supportsDST": 1, "CountryCode": "UY" }, { "offsetFromUTC": -180, "Country": "Falkland Islands", "mcc": 750, "supportsDST": 1, "CountryCode": "FK" } ] }
            };
        }
        else if(args.key == "region") {
            message = { 
                "returnValue": true , "region": [ { "shortCountryName": "Afghanistan", "countryName": "Afghanistan", "countryCode": "af" }, { "shortCountryName": "Algeria", "countryName": "Algeria", "countryCode": "dz" }, { "shortCountryName": "Angola", "countryName": "Angola", "countryCode": "ao" }, { "shortCountryName": "Argentina", "countryName": "Argentina", "countryCode": "ar" }, { "shortCountryName": "Armenia", "countryName": "Armenia", "countryCode": "am" }, { "shortCountryName": "Albania", "countryName": "Albania", "countryCode": "al" }, { "shortCountryName": "Australia", "countryName": "Australia", "countryCode": "au" }, { "shortCountryName": "Austria", "countryName": "Austria", "countryCode": "at" }, { "shortCountryName": "Azerbaijan", "countryName": "Azerbaijan", "countryCode": "az" }, { "shortCountryName": "Bahrain", "countryName": "Bahrain", "countryCode": "bh" }, { "shortCountryName": "Belarus", "countryName": "Belarus", "countryCode": "by" }, { "shortCountryName": "Belgium", "countryName": "Belgium", "countryCode": "be" }, { "shortCountryName": "Benin", "countryName": "Benin", "countryCode": "bj" }, { "shortCountryName": "Bolivia", "countryName": "Bolivia", "countryCode": "bo" }, { "shortCountryName": "Bosnia", "countryName": "Bosnia", "countryCode": "ba" }, { "shortCountryName": "Brazil", "countryName": "Brazil", "countryCode": "br" }, { "shortCountryName": "Bulgaria", "countryName": "Bulgaria", "countryCode": "bg" }, { "shortCountryName": "Burkina Faso", "countryName": "Burkina Faso", "countryCode": "bf" }, { "shortCountryName": "Cameroon", "countryName": "Cameroon", "countryCode": "cm" }, { "shortCountryName": "Canada", "countryName": "Canada", "countryCode": "ca" }, { "shortCountryName": "Cape Verde", "countryName": "Cape Verde", "countryCode": "cv" }, { "shortCountryName": "Africa", "countryName": "Central African Republic", "countryCode": "cf" }, { "shortCountryName": "Chile", "countryName": "Chile", "countryCode": "cl" }, { "shortCountryName": "China", "countryName": "China", "countryCode": "cn" }, { "shortCountryName": "Colombia", "countryName": "Colombia", "countryCode": "co" }, { "shortCountryName": "Congo", "countryName": "Congo, The Democratic Republic of the", "countryCode": "cd" }, { "shortCountryName": "Costa Rica", "countryName": "Costa Rica", "countryCode": "cr" }, { "shortCountryName": "Croatia", "countryName": "Croatia", "countryCode": "hr" }, { "shortCountryName": "Cyprus", "countryName": "Cyprus", "countryCode": "cy" }, { "shortCountryName": "Czech ", "countryName": "Czech Republic", "countryCode": "cz" }, { "shortCountryName": "Denmark", "countryName": "Denmark", "countryCode": "dk" }, { "shortCountryName": "Djibouti", "countryName": "Djibouti", "countryCode": "dj" }, { "shortCountryName": "Dominican Republic", "countryName": "Dominican Republic", "countryCode": "do" }, { "shortCountryName": "Ecuador", "countryName": "Ecuador", "countryCode": "ec" }, { "shortCountryName": "Egypt", "countryName": "Egypt", "countryCode": "eg" }, { "shortCountryName": "El Salvador", "countryName": "El Salvador", "countryCode": "sv" }, { "shortCountryName": "Estonia", "countryName": "Estonia", "countryCode": "ee" }, { "shortCountryName": "Ethiopia", "countryName": "Ethiopia", "countryCode": "et" }, { "shortCountryName": "Finland", "countryName": "Finland", "countryCode": "fi" }, { "shortCountryName": "France", "countryName": "France", "countryCode": "fr" }, { "shortCountryName": "Gabon", "countryName": "Gabon", "countryCode": "ga" }, { "shortCountryName": "Gambia", "countryName": "Gambia", "countryCode": "gm" }, { "shortCountryName": "Georgia", "countryName": "Georgia", "countryCode": "ge" }, { "shortCountryName": "Germany", "countryName": "Germany", "countryCode": "de" }, { "shortCountryName": "Ghana", "countryName": "Ghana", "countryCode": "gh" }, { "shortCountryName": "Greece", "countryName": "Greece", "countryCode": "gr" }, { "shortCountryName": "Guatemala", "countryName": "Guatemala", "countryCode": "gt" }, { "shortCountryName": "Guinea Equatorial", "countryName": "Guinea Equatorial", "countryCode": "gq" }, { "shortCountryName": "Guinea Equatorial", "countryName": "Guinea Equatorial", "countryCode": "cq" }, { "shortCountryName": "Guinea", "countryName": "Guinea", "countryCode": "gn" }, { "shortCountryName": "Honduras", "countryName": "Honduras", "countryCode": "hn" }, { "shortCountryName": "Hong Kong", "countryName": "Hong Kong", "countryCode": "hk" }, { "shortCountryName": "Hungary", "countryName": "Hungary", "countryCode": "hu" }, { "shortCountryName": "Iceland", "countryName": "Iceland", "countryCode": "is" }, { "shortCountryName": "India", "countryName": "India", "countryCode": "in" }, { "shortCountryName": "Indonesia", "countryName": "Indonesia", "countryCode": "id" }, { "shortCountryName": "Iran", "countryName": "Iran", "countryCode": "ir" }, { "shortCountryName": "Iraq", "countryName": "Iraq", "countryCode": "iq" }, { "shortCountryName": "Ireland", "countryName": "Ireland", "countryCode": "ie" }, { "shortCountryName": "Israel", "countryName": "Israel", "countryCode": "il" }, { "shortCountryName": "Italy", "countryName": "Italy", "countryCode": "it" }, { "shortCountryName": "Ivory Coast", "countryName": "Ivory Coast", "countryCode": "ci" }, { "shortCountryName": "Jamaica", "countryName": "Jamaica", "countryCode": "jm" }, { "shortCountryName": "Japan", "countryName": "Japan", "countryCode": "jp" }, { "shortCountryName": "Jordan", "countryName": "Jordan", "countryCode": "jo" }, { "shortCountryName": "Kazakhstan", "countryName": "Kazakhstan", "countryCode": "kz" }, { "shortCountryName": "Kenya", "countryName": "Kenya", "countryCode": "ke" }, { "shortCountryName": "Korea", "countryName": "Korea, Republic of", "countryCode": "kr" }, { "shortCountryName": "Kuwait", "countryName": "Kuwait", "countryCode": "kw" }, { "shortCountryName": "Kyrgyzstan", "countryName": "IKyrgyzstan", "countryCode": "kg" }, { "shortCountryName": "Latvia", "countryName": "Latvia", "countryCode": "lv" }, { "shortCountryName": "Lebanon", "countryName": "Lebanon", "countryCode": "lb" }, { "shortCountryName": "Lesotho", "countryName": "Lesotho", "countryCode": "ls" }, { "shortCountryName": "Liberia", "countryName": "Liberia", "countryCode": "lr" }, { "shortCountryName": "Libya", "countryName": "Libya", "countryCode": "ly" }, { "shortCountryName": "Lithuania", "countryName": "Lithuania", "countryCode": "lt" }, { "shortCountryName": "Luxembourg", "countryName": "Luxembourg", "countryCode": "lu" }, { "shortCountryName": "Macedonia", "countryName": "Macedonia, The Former Yugoslav Republic Of", "countryCode": "mk" }, { "shortCountryName": "Malawi", "countryName": "Malawi", "countryCode": "mw" }, { "shortCountryName": "Malaysia", "countryName": "Malaysia", "countryCode": "my" }, { "shortCountryName": "Mali", "countryName": "Mali", "countryCode": "ml" }, { "shortCountryName": "Malta", "countryName": "Malta", "countryCode": "mt" }, { "shortCountryName": "Mauritania", "countryName": "Mauritania", "countryCode": "mr" }, { "shortCountryName": "Mauritius", "countryName": "Mauritius", "countryCode": "mu" }, { "shortCountryName": "Mongolia", "countryName": "Mongolia", "countryCode": "mn" }, { "shortCountryName": "Montenegro", "countryName": "Montenegro", "countryCode": "me" }, { "shortCountryName": "Morocco", "countryName": "Morocco", "countryCode": "ma" }, { "shortCountryName": "Mexico", "countryName": "Mexico", "countryCode": "mx" }, { "shortCountryName": "Mozambique", "countryName": "Mozambique", "countryCode": "mz" }, { "shortCountryName": "Myanmar", "countryName": "Myanmar", "countryCode": "mm" }, { "shortCountryName": "Netherlands", "countryName": "Netherlands", "countryCode": "nl" }, { "shortCountryName": "New Zealand", "countryName": "New Zealand", "countryCode": "nz" }, { "shortCountryName": "Nicaragua", "countryName": "Nicaragua", "countryCode": "ni" }, { "shortCountryName": "Nigeria", "countryName": "Nigeria", "countryCode": "ng" }, { "shortCountryName": "Norway", "countryName": "Norway", "countryCode": "no" }, { "shortCountryName": "Oman", "countryName": "Oman", "countryCode": "om" }, { "shortCountryName": "Pakistan", "countryName": "Pakistan", "countryCode": "pk" }, { "shortCountryName": "Panama", "countryName": "Panama", "countryCode": "pa" }, { "shortCountryName": "Paraguay", "countryName": "Paraguay", "countryCode": "py" }, { "shortCountryName": "Peru", "countryName": "Peru", "countryCode": "pe" }, { "shortCountryName": "Philippines", "countryName": "Philippines", "countryCode": "ph" }, { "shortCountryName": "Poland", "countryName": "Poland", "countryCode": "pl" }, { "shortCountryName": "Portugal", "countryName": "Portugal", "countryCode": "pt" }, { "shortCountryName": "Puerto Rico", "countryName": "Puerto Rico", "countryCode": "pr" }, { "shortCountryName": "Qatar", "countryName": "Qatar", "countryCode": "qa" }, { "shortCountryName": "Republic of the Congo", "countryName": "Republic of the Congo", "countryCode": "cg" }, { "shortCountryName": "Romania", "countryName": "Romania", "countryCode": "ro" }, { "shortCountryName": "Russian Federation", "countryName": "Russian Federation", "countryCode": "ru" }, { "shortCountryName": "Rwanda", "countryName": "Rwanda", "countryCode": "rw" }, { "shortCountryName": "Saudi Arabia", "countryName": "Saudi Arabia", "countryCode": "sa" }, { "shortCountryName": "Senegal", "countryName": "Senegal", "countryCode": "sn" }, { "shortCountryName": "Serbia", "countryName": "Serbia", "countryCode": "rs" }, { "shortCountryName": "Sierra Leone", "countryName": "Sierra Leone", "countryCode": "sl" }, { "shortCountryName": "Singapore", "countryName": "Singapore", "countryCode": "sg" }, { "shortCountryName": "Slovakia", "countryName": "Slovakia", "countryCode": "sk" }, { "shortCountryName": "Slovenia", "countryName": "Slovenia", "countryCode": "si" }, { "shortCountryName": "South Africa", "countryName": "South Africa", "countryCode": "za" }, { "shortCountryName": "Spain", "countryName": "Spain", "countryCode": "es" }, { "shortCountryName": "Sri Lanka", "countryName": "Sri Lanka", "countryCode": "lk" }, { "shortCountryName": "Sudan", "countryName": "Sudan", "countryCode": "sd" }, { "shortCountryName": "Sweden", "countryName": "Sweden", "countryCode": "se" }, { "shortCountryName": "Switzerland", "countryName": "Switzerland", "countryCode": "ch" }, { "shortCountryName": "Syria", "countryName": "Syria", "countryCode": "sy" }, { "shortCountryName": "Taiwan", "countryName": "Taiwan", "countryCode": "tw" }, { "shortCountryName": "Tanzania", "countryName": "Tanzania, United Republic of", "countryCode": "tz" }, { "shortCountryName": "Thailand", "countryName": "Thailand", "countryCode": "th" }, { "shortCountryName": "Togo", "countryName": "Togo", "countryCode": "tg" }, { "shortCountryName": "Tunisia", "countryName": "Tunisia", "countryCode": "tn" }, { "shortCountryName": "Turkey", "countryName": "Turkey", "countryCode": "tr" }, { "shortCountryName": "UAE", "countryName": "United Arab Emirates", "countryCode": "ae" }, { "shortCountryName": "United Kingdom", "countryName": "United Kingdom", "countryCode": "gb" }, { "shortCountryName": "Uganda", "countryName": "Uganda", "countryCode": "ug" }, { "shortCountryName": "Ukraine", "countryName": "Ukraine", "countryCode": "ua" }, { "shortCountryName": "Uruguay", "countryName": "Uruguay", "countryCode": "uy" }, { "shortCountryName": "USA", "countryName": "United States of America", "countryCode": "us" }, { "shortCountryName": "Uzbekistan", "countryName": "Uzbekistan", "countryCode": "uz" }, { "shortCountryName": "Venezuela", "countryName": "Venezuela", "countryCode": "ve" }, { "shortCountryName": "Vietnam", "countryName": "Vietnam", "countryCode": "vn" }, { "shortCountryName": "Yemen", "countryName": "Yemen", "countryCode": "ye" }, { "shortCountryName": "Zambia", "countryName": "Zambia", "countryCode": "zm" } ]
            };
        }
        else {
            console.log("We don't have preference values for: "+args.keys);
        }

        returnFct({payload: JSON.stringify(message)});
    }

    function wifiConnect_call(args, returnFct, handleError) {
        var message = {
            "returnValue":true
        };

        returnFct({payload: JSON.stringify(message)});
    }

    function wanSet_call(args, returnFct, handleError) {
        var message = {
            "returnValue":true
        };

        returnFct({payload: JSON.stringify(message)});
    }

    function wifiSetState_call(args, returnFct, handleError) {
        var message = {
            "returnValue":true
        };

        returnFct({payload: JSON.stringify(message)});
    }

    function getBatteryStatusQuery_call(args, returnFct, handleError) {
        var message = {
            "returnValue": true,
            "percent_ui": 10
        };

        returnFct({payload: JSON.stringify(message)});
    }

    function getChargerStatusQuery_call(args, returnFct, handleError) {
        var message = {
            "returnValue": true,
            "Charging": false
        };

        returnFct({payload: JSON.stringify(message)});
    }

    function getConnectionManagerStatus_call(args, returnFct, handleError) {
        console.log("GetConnectionManagerStatus is called");
    }

    function getConnectionManagerInfo_call(args, returnFct, handleError) {
        var message = {
            "returnValue": true,
            "wifiInfo": {"macAddress": "00:11:22:33:44:55"}
        };

        returnFct({payload: JSON.stringify(message)});
    }

    function findDb_call(args, returnFct, handleError) {
        var message = {};
        if(args.query.from ==="com.palm.browserhistory:1") {
            message = {
                "returnValue":true,
                "results":[{"_id":"browserhistorytest1","_kind":"com.palm.browserhistory:1","_rev":599,"_sync":true,"date":1439655155269,"title":"WebOS Ports","url":"http://www.webos-ports.org/"},{"_id":"browserhistorytest2","_kind":"com.palm.browserhistory:1","_rev":600,"_sync":true,"date":1439655173937,"title":"PivotCE","url":"http://pivotce.com/"},{"_id":"browserhistorytest3","_kind":"com.palm.browserhistory:1","_rev":1629,"_sync":true,"date":1439894450703,"title":"WebOS Nation - Forum","url":"http://forums.webosnation.com/"}]
            };
        }
        else if(args.query.from ==="com.palm.browserbookmarks:1") {
            message = {
                "returnValue":true,
                "results":[{"_id":"browserbookmarkstest1","_kind":"com.palm.browserbookmarks:1","_rev":599,"_sync":true,"date":1439655155269,"title":"WebOS Internals","url":"http://www.webos-internals.org/"},{"_id":"browserbookmarkstest2","_kind":"com.palm.browserbookmarks:1","_rev":600,"_sync":true,"date":1439655173937,"title":"WebOS Nation","url":"http://www.webosnation.com/"},{"_id":"browserbookmarkstest3","_kind":"com.palm.browserbookmarks:1","_rev":1629,"_sync":true,"date":1439894450703,"title":"LG SVL","url":"http://www.lgsvl.com/"}]
            };
        }
        else if(args.query.from ==="com.palm.phonecallgroup:1") {
            message = {
                "returnValue":true, 
                "results":[]
            };
        }
        else if(args.query.from ==="com.palm.browserpreferences:1") {
            message = {
                "returnValue": true,
                "results": [
                    {
                        "key": "blockPopups",
                        "value": true
                    },
                    {
                        "key": "acceptCookies",
                        "value": true
                    },
                    {
                        "key": "enableJavascript",
                        "value": false
                    },
                    {
                        "key": "rememberPasswords",
                        "value": false
                    },
                    {
                        "key": "enablePlugins",
                        "value": true
                    }
                ]
            };
        }
        else {
            console.log("Others: "+args.query.from)
        }
        returnFct({payload: JSON.stringify(message)});
    }

    function mergeDb_call(args, returnFct, handleError) {
        var message = {}
        if(args.query.from ==="com.palm.browserpreferences:1") {
            message = {
                "returnValue":true
            }
        }
        else {
            console.log("Others: "+args.query.from)
        }
        if(typeof returnFct !== 'undefined') {
            returnFct({"payload": JSON.stringify(message)});
        }
    }

    function getConfigs_call(args, returnFct, handleError) {
        var message
        message = {
            "returnValue":true,
            "configs": [{"config": "feedspider.conf", "enabled": false, "contents": "src/gz FeedSpider2 http://feedspider.net/luneos"}, {"config": "hominid-software.conf", "enabled": false, "contents": "src Hominid-Software http://hominidsoftware.com/preware"}, {"config": "macaw-enyo.conf", "enabled": false, "contents": "src Macaw-enyo http://minego.net/preware/macaw-enyo"}, {"config": "pivotce.conf", "enabled": false, "contents": "src PivotCE http://feed.pivotce.com"}, {"config": "webos-ports.conf", "enabled": true, "contents": "src/gz webosports http://feeds.webos-ports.org/webos-ports/all"}]
        };
        returnFct({payload: JSON.stringify(message)});
    }

    function setConfigState_call(args, returnFct, handleError) {
        var message
        message = {
            "returnValue":true,
            "stdOut": []
        };
        returnFct({payload: JSON.stringify(message)});
    }

    function matchDevicePasscode_call(args, returnFct, handleError) {
        var success = (args.passCode === configuredPasscode);

        if(retriesLeft == 0) {
            success = false;
        };

        if(!success) {
            if(retriesLeft == 0) {
                /* FIXME */
            }
            else {
                retriesLeft = retriesLeft - 1;
            }
        }

        var message = {
            returnValue: success,
            retriesLeft: retriesLeft,
            lockedOut: false
        };

        returnFct({payload: JSON.stringify(message)});
    }

    function getTweaks_call(args, returnFct, handleError) {

        //return preference value for locale
        if(args.keys == "dialPadFeedback") {
            var message = {
                "returnValue": true,
                "dialPadFeedback": "vibrateOnly"
            };
        }
        else if(args.keys == "alwaysShowProgressBarKey") {
            var message = {
                "returnValue": true,
                "alwaysShowProgressBarKey": true
            };
        }
        else if(args.keys == "privateByDefaultKey") {
            var message = {
                "returnValue": true,
                "privateByDefaultKey": true
            };
        }
        else if(args.keys == "toggleVKBKey") {
            var message = {
                "returnValue": true,
                "toggleVKBKey": true
            };
        }
        else if(args.keys == "tapRippleSupport") {
            var message = {
                "returnValue": true,
                "tapRippleSupport": true
            };
        }
        else if(args.keys == "showGestureArea") {
            var message = {
                "returnValue": true,
                "showGestureArea": true
            };
        }
        else if(args.keys == "tabTitleCase") {
            var message = {
                "returnValue": true,
                "tabTitleCase": "upperCase"
            };
        }
        else if(args.keys == "tabIndicatorNumber") {
            var message = {
                "returnValue": true,
                "tabIndicatorNumber": "default"
            };
        }
        else if(args.keys == "stackedCardSupport") {
            var message = {
                "returnValue": true,
                "stackedCardSupport": true
            };
        }
        else if(args.keys == "showDateTime") {
            var message = {
                "returnValue": true,
                "showDateTime": "timeOnly"
            };
        }
        else if(args.keys == "showBatteryPercentage") {
            var message = {
                "returnValue": true,
                "showBatteryPercentage": "iconOnly"
            };
        }
        else if(args.keys == "batteryPercentageColor") {
            var message = {
                "returnValue": true,
                "batteryPercentageColor": "white"
            };
        }
        else if(args.keys == "useCustomCarrierString") {
            var message = {
                "returnValue": true,
                "useCustomCarrierString": false
            };
        }
        else if(args.keys == "carrierString") {
            var message = {
                "returnValue": true,
                "carrierString": "LuneOS"
            };
        }
        else {
            console.log("We don't have a Tweak for: "+args.keys);
        }
        returnFct({payload: JSON.stringify(message)});
    }

    function getUniversalSearch_call(args, returnFct, handleError) {
        var message = { 
            "returnValue": true, 
            "UniversalSearchList": [ { "id": "google", "displayName": "Google", "iconFilePath": "\/usr\/palm\/applications\/com.palm.launcher\/images\/search-icon-google.png", "url": "https:\/\/www.google.com\/search?q=#{searchTerms}", "suggestURL": "https:\/\/encrypted.google.com\/complete\/search?hl=en&output=firefox&q=#{searchTerms}", "launchParam": "", "type": "web", "enabled": true }, { "id": "wikipedia", "displayName": "Wikipedia", "iconFilePath": "\/usr\/palm\/applications\/com.palm.launcher\/images\/search-icon-wikipedia.png", "url": "https:\/\/en.wikipedia.org\/wiki\/Special:Search?search=#{searchTerms}", "suggestURL": "https:\/\/en.wikipedia.org\/w\/api.php?action=opensearch&search=#{searchTerms}&limit=8&namespace=0&format=json", "launchParam": "", "type": "web", "enabled": true }, { "id": "duckduckgo", "displayName": "DuckDuckGo", "iconFilePath": "\/usr\/palm\/applications\/com.palm.launcher\/images\/search-icon-duckduckgo.png", "url": "https:\/\/www.duckduckgo.com\/?q=#{searchTerms}", "suggestURL": "", "launchParam": "", "type": "web", "enabled": true }, { "id": "cnn", "displayName": "CNN", "iconFilePath": "\/usr\/palm\/applications\/com.palm.launcher\/images\/search-icon-cnn.png", "url": "http:\/\/www.cnn.com\/search\/?query=#{searchTerms}", "suggestURL": "", "launchParam": "", "type": "web", "enabled": false }, { "id": "amazon", "displayName": "Amazon", "iconFilePath": "\/usr\/palm\/applications\/com.palm.launcher\/images\/search-icon-amazon.png", "url": "https:\/\/www.amazon.com\/s\/?k=#{searchTerms}", "suggestURL": "", "launchParam": "", "type": "web", "enabled": false }, { "id": "imdb", "displayName": "IMDb", "iconFilePath": "\/usr\/palm\/applications\/com.palm.launcher\/images\/search-icon-imdb.png", "url": "http:\/\/www.imdb.com\/find?q=#{searchTerms}", "suggestURL": "", "launchParam": "", "type": "web", "enabled": false } ], "ActionList": [ { "id": "com.palm.app.email", "displayName": "New Email", "iconFilePath": "\/usr\/palm\/applications\/com.palm.app.email\/icon.png", "url": "com.palm.app.email", "launchParam": "text", "enabled": true }, { "id": "com.palm.app.calendar", "displayName": "New Event", "iconFilePath": "\/usr\/palm\/applications\/com.palm.app.calendar\/images\/icon-256x256.png", "url": "com.palm.app.calendar", "launchParam": "quickLaunchText", "enabled": true }, { "id": "org.webosports.app.messaging", "displayName": "New Message", "iconFilePath": "\/usr\/palm\/applications\/org.webosports.app.messaging\/icon.png", "url": "org.webosports.app.messaging", "launchParam": "{ \"compose\": { \"messageText\": \"#{searchTerms}\" } }", "enabled": true } ], "DBSearchItemList": [ { "id": "com.palm.app.email", "displayName": "Email", "iconFilePath": "\/usr\/palm\/applications\/com.palm.app.email\/icon.png", "launchParam": "emailId", "launchParamDbField": "_id", "dbQuery": { "from": "com.palm.email:1", "where": [ { "prop": "flags.visible", "op": "=", "val": true }, { "prop": "searchText", "op": "?", "val": "", "collate": "primary" } ], "orderBy": "timestamp", "desc": true, "limit": 20 }, "displayFields": [ "from.name", "subject" ], "batchQuery": false, "enabled": true }, { "id": "com.palm.app.calendar", "displayName": "Calendar Events", "iconFilePath": "\/usr\/palm\/applications\/com.palm.app.calendar\/images\/icon-256x256.png", "launchParam": "showEventDetail", "launchParamDbField": "_id", "dbQuery": { "from": "com.palm.calendarevent:1", "where": [ { "prop": "searchText", "op": "?", "val": "", "collate": "primary" } ], "orderBy": "subject", "desc": false, "limit": 20 }, "displayFields": [ "subject", { "name": "dtstart", "type": "timestamp" } ], "batchQuery": false, "enabled": true } ], 
            "defaultSearchEngine": "google", 
            "subscribed": false 
        };
        returnFct({payload: JSON.stringify(message)});
    }

    function retrieveVersion_call(args, returnFct, handleError) {
        var message = {
            "returnValue": true,
            "localVersion": "2017.11",
            "codename": "Doppio",
            "buildTree": "testing",
            "buildNumber": "0"
        };
        returnFct({payload: JSON.stringify(message)});
    }

    function androidGetProperty_call(args, returnFct, handleError) {
        var supportedProperties = {
            "ro.serialno": "01234567890abde",
            "ro.product.model": "Model X",
            "ro.product.manufacturer": "Lune",
            "ro.build.version.release": "5.1.1"
        };
        var propertiesValues = [];

        for (var i in args.keys) {
            var obj = {};
            if(supportedProperties.hasOwnProperty(args.keys[i])) {
                obj[args.keys[i]] = supportedProperties[args.keys[i]];
                propertiesValues.push(obj);
            }
        }

        var message = {
            "returnValue": true,
            "properties": propertiesValues
        };
        returnFct({payload: JSON.stringify(message)});
    }
}
