/*
 * (c) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12

/*
 * The parameters an app was launched or relaunched with.
 *
 *     WebOSWindow {
 *         id: root
 *         LaunchParams {
 *             window: root
 *             onLaunched: (params) => if (params.target) openTarget(params.target)
 *             onAppMenuRequested: appMenu.popup(0, 0)
 *         }
 *     }
 *
 * qml-runner, which starts QML apps, hands them over as the window's
 * launchParams string, at launch and on every relaunch. That property only
 * notifies when it changes, and the status bar asks for the app menu by
 * relaunching with the same parameters each time, so once handled it is
 * cleared here and the next identical relaunch is a change again. Camera
 * read only the older launcher's "application" object, which qml-runner
 * does not provide, and its app menu never opened; that object is still
 * followed when it exists.
 */
QtObject {
    id: launch

    // The app's window: the WebOSWindow qml-runner created
    property var window: null

    // The latest parameters, unwrapped
    readonly property var params: _params

    // Every launch or relaunch that carried parameters
    signal launched(var params)
    // The status bar's app-menu button ("palm-command": "open-app-menu")
    signal appMenuRequested()
    // Any other palm-command, by name
    signal command(string name, var params)

    property var _params: ({})

    function _handleText(text) {
        if (!text)
            return;
        var params;
        try {
            params = JSON.parse(text);
        } catch (error) {
            console.warn("LaunchParams: cannot parse " + text + ": " + error);
            return;
        }
        if (window && window.launchParams)
            window.launchParams = "";
        _handle(params);
    }

    function _handle(params) {
        if (!params || typeof params !== "object")
            return;
        _params = params;
        launched(params);

        // The status bar puts the command at the top level or one "params" down
        var name = params["palm-command"]
                || (params.params ? params.params["palm-command"] : undefined);
        if (name === "open-app-menu")
            appMenuRequested();
        else if (name)
            command(name, params);
    }

    property Connections _fromWindow: Connections {
        target: launch.window
        ignoreUnknownSignals: true
        function onLaunchParamsChanged() { launch._handleText(launch.window.launchParams); }
    }

    property Connections _fromApplication: Connections {
        target: typeof application !== "undefined" ? application : null
        ignoreUnknownSignals: true
        function onRelaunched(parameters) { launch._handleText(parameters); }
    }

    Component.onCompleted: {
        if (window && window.launchParams)
            _handleText(window.launchParams);
        else if (typeof application !== "undefined" && application.launchParameters)
            _handleText(application.launchParameters);
    }
}
