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
import org.kde.bluezqt 1.0 as BluezQt

import "../modules/LuneOS/Bluetooth/BluetoothPolicy.js" as Policy

/*
 * LuneOS.Bluetooth's BluetoothManager against the BluezQt stand-in in
 * test/imports/org/kde/bluezqt: a search stops by itself, "Search again"
 * runs another, and a device the user paired comes out trusted.
 *   qmltestrunner -import modules -import test/imports -input test/tst_bluetooth_manager.qml
 *
 * The module's qmldir loads its C++ plugin, which needs KF6 BluezQt and is
 * not built here; and a file next to that qmldir cannot be loaded without
 * it. So the manager's source is read (QML_XHR_ALLOW_FILE_READ=1, as
 * run-tests.sh sets) and created here, a fresh one per test rather than the
 * module's singleton, with its BluetoothPolicy.js import pointed back at
 * the module.
 */
Item {
    id: root

    TestCase {
        name: "BluetoothManager"

        readonly property var fake: BluezQt.Manager

        readonly property url moduleDir: Qt.resolvedUrl("../modules/LuneOS/Bluetooth/")
        property string source: ""

        function initTestCase() {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", moduleDir + "BluetoothManager.qml", false);
            xhr.send();
            verify(xhr.responseText.length > 0, "BluetoothManager.qml could not be read; QML_XHR_ALLOW_FILE_READ=1?");
            source = xhr.responseText
                .replace("pragma Singleton", "")
                .replace('import "BluetoothPolicy.js"', 'import "' + moduleDir + 'BluetoothPolicy.js"');
            verify(source.indexOf(moduleDir + "BluetoothPolicy.js") >= 0, "the Policy import moved");
        }

        // A fresh manager; fake.usableAdapter as the test left it.
        function createManager(props) {
            var manager = Qt.createQmlObject(source, root, "BluetoothManagerUnderTest.qml");
            verify(manager !== null, "the manager did not load");
            managers = managers.concat([manager]);
            for (var key in props)
                manager[key] = props[key];
            return manager;
        }

        function makeManager(props) {
            fake.reset();
            return createManager(props || {});
        }

        property var managers: []

        function cleanup() {
            // The fakes' discovering must not outlive a manager left running.
            for (var i = 0; i < managers.length; ++i)
                managers[i].destroy();
            managers = [];
        }

        function count(what) {
            return fake.calls.filter(function(c) { return c === what; }).length;
        }

        // The pure decisions first.

        function test_policy_discoveryAction_data() {
            return [
                { tag: "no adapter",         wanted: true,  adapter: false, discovering: false, timedOut: false, expected: "none" },
                { tag: "wanted, idle",       wanted: true,  adapter: true,  discovering: false, timedOut: false, expected: "start" },
                { tag: "wanted, running",    wanted: true,  adapter: true,  discovering: true,  timedOut: false, expected: "none" },
                { tag: "timed out, running", wanted: true,  adapter: true,  discovering: true,  timedOut: true,  expected: "stop" },
                { tag: "timed out, idle",    wanted: true,  adapter: true,  discovering: false, timedOut: true,  expected: "none" },
                { tag: "unwanted, running",  wanted: false, adapter: true,  discovering: true,  timedOut: false, expected: "stop" },
                { tag: "unwanted, idle",     wanted: false, adapter: true,  discovering: false, timedOut: false, expected: "none" },
            ];
        }
        function test_policy_discoveryAction(data) {
            compare(Policy.discoveryAction(data.wanted, data.adapter, data.discovering, data.timedOut), data.expected);
        }

        function test_policy_shouldTrust() {
            verify(!Policy.shouldTrust(null));
            verify(!Policy.shouldTrust({ paired: false, trusted: false }));
            verify(Policy.shouldTrust({ paired: true, trusted: false }));
            verify(!Policy.shouldTrust({ paired: true, trusted: true }));
        }

        function test_policy_searchIsBounded() {
            verify(Policy.discoveryTimeoutMs >= 10240, "shorter than one BR/EDR inquiry");
            verify(Policy.discoveryTimeoutMs <= 60000, "searches for more than a minute");
        }

        // The manager.

        function test_searchStartsWhenAListIsShown() {
            var manager = makeManager();
            compare(count("startDiscovery"), 0);
            verify(!manager.discovering);
            manager.discoveringMode = true;
            compare(count("startDiscovery"), 1);
            verify(manager.discovering);
            manager.discoveringMode = false;
            compare(count("stopDiscovery"), 1);
            verify(!manager.discovering);
        }

        function test_searchStopsByItself() {
            var manager = makeManager({ discoveryTimeoutMs: 200 });
            manager.discoveringMode = true;
            verify(manager.discovering);
            tryCompare(manager, "discovering", false, 2000);
            compare(count("stopDiscovery"), 1);
            // Still wanted, but not run again until asked.
            verify(manager.discoveringMode);
            wait(400);
            compare(count("startDiscovery"), 1);
        }

        function test_searchAgainRunsAnother() {
            var manager = makeManager({ discoveryTimeoutMs: 200 });
            manager.discoveringMode = true;
            tryCompare(manager, "discovering", false, 2000);
            manager.searchAgain();
            verify(manager.discovering);
            compare(count("startDiscovery"), 2);
            tryCompare(manager, "discovering", false, 2000);
        }

        function test_showingTheListAgainRunsAnother() {
            var manager = makeManager({ discoveryTimeoutMs: 200 });
            manager.discoveringMode = true;
            tryCompare(manager, "discovering", false, 2000);
            manager.discoveringMode = false;
            manager.discoveringMode = true;
            verify(manager.discovering);
            compare(count("startDiscovery"), 2);
        }

        function test_anAdapterTurningUpStartsTheSearch() {
            fake.reset();
            fake.usableAdapter = null;
            var manager = createManager({ discoveringMode: true });
            compare(count("startDiscovery"), 0);
            fake.usableAdapter = fake.adapter;
            compare(count("startDiscovery"), 1);
            verify(manager.discovering);
        }

        function test_connectedIsFalseWithoutTheProperty() {
            // BluezQt's Adapter has no "connected"; undefined is not a bool.
            failOnWarning(/Unable to assign \[undefined\] to "connected"|Unable to assign \[undefined\] to bool/);
            var manager = makeManager();
            compare(manager.connected, false);
        }

        function test_pairingTrustsTheDevice() {
            var manager = makeManager();
            manager.connectDeviceAddress("74:1A:E0:20:8F:18");
            var device = fake.deviceForAddress("74:1A:E0:20:8F:18");
            compare(count("pair 74:1A:E0:20:8F:18"), 1);
            verify(!device.trusted);
            device.paired = true;
            verify(device.trusted, "a device the user paired was not trusted");
            compare(count("connect 74:1A:E0:20:8F:18"), 1);
        }

        function test_aFailedPairingTrustsNothing() {
            var manager = makeManager();
            manager.connectDeviceAddress("00:11:22:33:44:55");
            var device = fake.deviceForAddress("00:11:22:33:44:55");
            fake.pending[fake.pending.length - 1].finish(1);
            verify(!device.trusted);
            verify(!device.paired);
        }

        function test_connectingAPairedDeviceTrustsIt() {
            var manager = makeManager();
            var device = fake.deviceForAddress("00:11:22:33:44:66");
            device.paired = true;
            manager.connectDeviceAddress("00:11:22:33:44:66");
            compare(count("connect 00:11:22:33:44:66"), 1);
            verify(!device.trusted, "trusted before the connection was made");
            fake.pending[fake.pending.length - 1].finish(0);
            verify(device.trusted);
        }

        function test_aFailedConnectTrustsNothing() {
            var manager = makeManager();
            var device = fake.deviceForAddress("00:11:22:33:44:77");
            device.paired = true;
            manager.connectDeviceAddress("00:11:22:33:44:77");
            fake.pending[fake.pending.length - 1].finish(36);
            verify(!device.trusted);
        }
    }
}
