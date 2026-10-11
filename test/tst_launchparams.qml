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

import QtQuick
import QtTest
import LuneOS.System 1.0

/*
 * LaunchParams against a stand-in for the window qml-runner hands
 * parameters to:
 *   qmltestrunner -import modules -import test/imports -input test/tst_launchparams.qml
 */
TestCase {
    name: "LaunchParams"

    // What qml-runner writes to: WebOSWindow.launchParams, which only
    // notifies on a change
    QtObject {
        id: window
        property string launchParams: ""
    }

    LaunchParams { id: launch; window: window }

    SignalSpy { id: menu; target: launch; signalName: "appMenuRequested" }
    SignalSpy { id: launched; target: launch; signalName: "launched" }
    SignalSpy { id: command; target: launch; signalName: "command" }

    function init() {
        menu.clear();
        launched.clear();
        command.clear();
    }

    function relaunch(params) {
        window.launchParams = JSON.stringify(params);
    }

    function test_the_app_menu_opens_every_time() {
        // The status bar asks with the same parameters each time: the second
        // one has to arrive as well, which it only does if the first was
        // cleared once handled
        relaunch({ "palm-command": "open-app-menu" });
        relaunch({ "palm-command": "open-app-menu" });
        compare(menu.count, 2);
        compare(window.launchParams, "");
    }

    function test_the_command_can_sit_one_level_down() {
        relaunch({ "params": { "palm-command": "open-app-menu" } });
        compare(menu.count, 1);
    }

    function test_other_parameters_come_through_whole() {
        relaunch({ "target": "tel:123", "mode": "x" });
        compare(launched.count, 1);
        compare(launched.signalArguments[0][0].target, "tel:123");
        compare(launch.params.mode, "x");
        compare(menu.count, 0);
    }

    function test_other_commands_are_named() {
        relaunch({ "palm-command": "something-else" });
        compare(command.count, 1);
        compare(command.signalArguments[0][0], "something-else");
    }

    function test_garbage_is_ignored() {
        ignoreWarning(new RegExp("LaunchParams: cannot parse"));
        window.launchParams = "{not json";
        compare(launched.count, 0);
    }
}
