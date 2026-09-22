/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2026 WebOS Ports
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
 * The device this run is pretending to be.
 *
 * These were commented-out blocks that had to be swapped by editing this file,
 * which meant one checkout could only ever be run as one device -- so an app
 * that behaves differently on a tablet could not be tried both ways, and a
 * test could not cover both. The same values are named entries now, chosen on
 * the command line for an app run:
 *
 *     qml -I modules -I test/imports app.qml -- --profile=tp
 *
 * or with setProfile() below, which is how a test case walks all of them.
 * Anything unrecognised, or nothing at all, leaves the desktop profile in
 * force, which is what this file used to hold.
 */
var profiles = {
    /* A500 alike */
    "a500":    { tabletUi: true,  displayWidth: 1280, displayHeight:  800, dpi: 149, gridUnit: 10 },
    /* GNex alike */
    "gnex":    { tabletUi: false, displayWidth:  720, displayHeight: 1280, dpi: 264, gridUnit: 18 },
    /* N7 alike */
    "n7":      { tabletUi: true,  displayWidth: 1280, displayHeight:  800, dpi: 216, gridUnit: 14 },
    /* TP alike */
    "tp":      { tabletUi: true,  displayWidth: 1024, displayHeight:  768, dpi: 132, gridUnit: 10 },
    /* N4 alike */
    "n4":      { tabletUi: false, displayWidth:  768, displayHeight: 1280, dpi: 264, gridUnit: 18 },
    /* N5 alike */
    "n5":      { tabletUi: false, displayWidth: 1080, displayHeight: 1920, dpi: 445, gridUnit: 26 },
    /* For desktop debug */
    "desktop": { tabletUi: false, displayWidth:  600, displayHeight:  800, dpi: 148, gridUnit: 10 }
};

var defaultProfile = "desktop";

/*
 * A .pragma library sees no component context, but the Qt object is still
 * reachable, and with it whatever the runtime was invoked with.
 */
/*
 * The profile named on the command line, or null when none was. Kept apart
 * from selectedProfile() so a caller can tell "nothing was asked for" from
 * "desktop was asked for", and let an explicit flag win over its own choice.
 */
function commandLineProfile() {
    if (typeof Qt === "undefined" || !Qt.application || !Qt.application.arguments)
        return null;

    var args = Qt.application.arguments;
    for (var i = 0; i < args.length; ++i) {
        var arg = String(args[i]);
        var name = null;

        if (arg.indexOf("--profile=") === 0)
            name = arg.substring("--profile=".length);
        else if (arg === "--profile" && i + 1 < args.length)
            name = String(args[i + 1]);

        if (name !== null)
            return profiles.hasOwnProperty(name) ? name : null;
    }

    return null;
}

function selectedProfile() {
    return commandLineProfile() || defaultProfile;
}

/*
 * How much larger or smaller than normal the interface is drawn, from
 * --ui-scale=<n> on the command line.
 *
 * Parsed here, at load, for the same reason the profile is: every JavaScript
 * library that Qt.include()s this one gets its own copy of these variables,
 * so anything set later reaches only the copy it was set on. That is exactly
 * how the first attempt at this went wrong - Units grew, because the scale
 * was set on Units' copy, and text did not, because FontUtils reads a
 * different copy through its own include of UnitsStub. Deriving it from the
 * command line means every copy computes the same number without anybody
 * having to remember to tell them all.
 *
 * It also matches what the real Units does: read once, at construction, and
 * fixed for the life of the process - which is why the Accessibility panel
 * says a change takes effect the next time an application starts.
 *
 * Clamped to the range the real Units clamps to.
 */
function commandLineUiScale() {
    if (typeof Qt === "undefined" || !Qt.application || !Qt.application.arguments)
        return 1.0;

    var args = Qt.application.arguments;
    for (var i = 0; i < args.length; ++i) {
        var arg = String(args[i]);
        var value = null;

        if (arg.indexOf("--ui-scale=") === 0)
            value = arg.substring("--ui-scale=".length);
        else if (arg === "--ui-scale" && i + 1 < args.length)
            value = String(args[i + 1]);

        if (value !== null) {
            var scale = parseFloat(value);
            if (!isNaN(scale))
                return Math.max(0.75, Math.min(1.5, scale));
        }
    }

    return 1.0;
}

var uiScale = commandLineUiScale();

var isTestEnvironment = true;

var profileName;
var tabletUi;
var displayWidth;
var displayHeight;
var dpi;
var gridUnit;
var layoutScale;

/*
 * Switches the run to another device part-way through.
 *
 * qmltestrunner parses its own arguments and rejects anything it does not
 * know, so a test case cannot be handed --profile the way an app run can;
 * it calls this instead, and can walk every profile in one run.
 *
 * These are plain variables rather than properties, so bindings that have
 * already read them do not re-evaluate. A test that switches profile must
 * read what it is checking afterwards, and a component built beforehand keeps
 * the geometry it was built with.
 */
function setProfile(name) {
    if (!profiles.hasOwnProperty(name))
        return false;

    profileName   = name;
    tabletUi      = profiles[name].tabletUi;
    displayWidth  = profiles[name].displayWidth;
    displayHeight = profiles[name].displayHeight;
    dpi           = profiles[name].dpi;
    gridUnit      = profiles[name].gridUnit;
    layoutScale   = dpi / 132;
    return true;
}

setProfile(selectedProfile());

var displayFps = true;
var fontStatusBar = "Prelude"
var showReticle = false;

// not used
var lunaSystemResourcesPath = "./resourcesPath";
var splashIconSize = 64;
var gestureAreaHeight = 64;
var positiveSpaceTopPadding = 0;
var positiveSpaceBottomPadding = 0;
var hasBrightnessControl = true;
