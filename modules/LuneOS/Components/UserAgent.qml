/*
 * Copyright 2013-2014 Canonical Ltd.
 * Copyright 2014-2016 Herman van Hazendonk (github.com@herrie.org)
 *
 * This file is part of the LuneOS Web Browser App writing in QML and largely
 * based on the efforts from the Ubuntu team which uses it for their webbrowser-app.
 *
 * Both the LuneOS Web Browser App and Ubunut's webbrowser-app are free software;
 * you can redistribute it and/or modify it under the terms of the GNU General
 * Public License as published by the Free Software Foundation; version 3.
 *
 * LuneOS Web Browser App and Ubuntu's webbrowser-app are distributed in the hope that
 * they will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Window 2.0
import "js/ua-overrides.js" as Overrides

/*
 * Useful documentation:
 *   http://en.wikipedia.org/wiki/User_agent#Format
 *   https://developer.mozilla.org/en-US/docs/Gecko_user_agent_string_reference
 *   https://wiki.mozilla.org/B2G/User_Agent
 *   https://github.com/mozilla-b2g/gaia/blob/master/build/ua-override-prefs.js
 *   https://developers.google.com/chrome/mobile/docs/user-agent
 */

// This is an Item, not a QtObject, because it needs information about the Screen.
Item {
    // %1: form factor (Mobile, Tablet, Desktop)
    // %2: WebKit version
    //readonly property string _template: "Mozilla/5.0 (LuneOS; %1) WebKit/%2"
    readonly property string _template: "Mozilla/5.0 (LuneOS, like webOS/3.5.0; %1) AppleWebKit/%2 (KHTML, like Gecko) QtWebEngine/5.12.3 Chrome/69.0.3497.128 Safari/%2"

    // See Source/WebCore/Configurations/Version.xcconfig in QtWebKit’s source tree
    // TODO: determine this value at runtime
    readonly property string _webkitVersion: "537.36"

    // FIXME: this is a quick hack that will become increasingly unreliable
    // as we support more devices, so we need a better solution for this
    // FIXME: only handling phone and tablet for now, need to handle desktop too
    readonly property string _formFactor: (Screen.width >= 900) ? "Tablet" : "Mobile"

    property string defaultUA: _template.arg(_formFactor).arg(_webkitVersion)

    property var overrides: Overrides.overrides

    function getDomain(url) {
        var domain = url.toString().toLowerCase()
        var indexOfScheme = domain.indexOf("://")
        if (indexOfScheme !== -1) {
            domain = domain.slice(indexOfScheme + 3)
        }
        var indexOfPath = domain.indexOf("/")
        if (indexOfPath !== -1) {
            domain = domain.slice(0, indexOfPath)
        }
        return domain
    }

    function getDomains(domain) {
        var components = domain.split(".")
        var domains = []
        for (var i = 0; i < components.length; i++) {
            domains.push(components.slice(i).join("."))
        }
        return domains
    }

    function getUAString(url) {
        var ua = defaultUA
        var domains = getDomains(getDomain(url))
        for (var i = 0; i < domains.length; i++) {
            var domain = domains[i]
            if (domain in overrides) {
                var form = overrides[domain]
                if (typeof form == "string") {
                    return form
                } else if (typeof form == "object") {
                    return ua.replace(form[0], form[1])
                }
            }
        }
        return ua
    }
}
