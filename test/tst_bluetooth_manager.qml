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

import "../modules/LuneOS/Bluetooth/BluetoothPolicy.js" as Policy

/*
 * LuneOS.Bluetooth against a scripted com.webos.service.bluetooth2
 * (test/bluetooth2/FakeBluetooth2.qml): the adapter and its devices, a
 * search that stops by itself, pairing with the user asked, connecting, and
 * the agent for pairings a device starts.
 *   qmltestrunner -import modules -import test/imports -input test/tst_bluetooth_manager.qml
 *
 * test/imports has a stand-in LuneOS.Bluetooth for the shell's and Settings'
 * tests, which takes the module's name. So each file of the module is read
 * (QML_XHR_ALLOW_FILE_READ=1, as run-tests.sh sets) and created here from its
 * own directory - its qmldir and BluetoothPolicy.js resolve as on a device -
 * with the bus and ServiceStatus swapped for the fakes, and the manager a
 * fresh one per test rather than the module's singleton.
 */
Item {
    id: root

    readonly property url moduleDir: Qt.resolvedUrl("../modules/LuneOS/Bluetooth/")
    readonly property url fakesDir: Qt.resolvedUrl("bluetooth2")

    readonly property string headset: "74:1a:e0:20:8f:18"
    readonly property string speaker: "00:11:22:33:44:55"

    TestCase {
        name: "Bluetooth"
        when: windowShown

        property var made: []

        function read(file) {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", root.moduleDir + file, false);
            xhr.send();
            verify(xhr.responseText.length > 0, file + " could not be read; QML_XHR_ALLOW_FILE_READ=1?");
            return xhr.responseText;
        }

        // A file of the module, created as if it sat next to the real one.
        function create(file, replacements) {
            var source = read(file);
            for (var i = 0; i < replacements.length; i++) {
                verify(source.indexOf(replacements[i][0]) >= 0, file + ": \"" + replacements[i][0] + "\" moved");
                source = source.replace(replacements[i][0], replacements[i][1]);
            }
            source = source.replace("import QtQuick 2.0", "import QtQuick 2.0\nimport \"" + root.fakesDir + "\"");
            var object = Qt.createQmlObject(source, root, root.moduleDir + file.replace(".qml", ".test.qml"));
            verify(object !== null, file + " did not load");
            made = made.concat([object]);
            return object;
        }

        function makeManager(props) {
            var manager = create("BluetoothManager.qml", [
                ["pragma Singleton", ""],
                ["LunaService {", "FakeBluetooth2 {"],
                ["ServiceStatus {", "FakeServiceStatus {"]
            ]);
            for (var key in props)
                manager[key] = props[key];
            tryCompare(manager, "bluetoothOperational", true, 1000);
            return manager;
        }

        function makeModel(manager, props) {
            var model = create("BluetoothDevicesModel.qml", [
                ["property QtObject manager: BluetoothManager", "property QtObject manager: null"]
            ]);
            for (var key in props)
                model[key] = props[key];
            model.manager = manager;
            return model;
        }

        function makeAgent(manager) {
            var agent = create("LuneOSBluetoothAgent.qml", [
                ["property QtObject manager: BluetoothManager", "property QtObject manager: null"]
            ]);
            agent.manager = manager;
            return agent;
        }

        function cleanup() {
            for (var i = made.length - 1; i >= 0; --i)
                made[i].destroy();
            made = [];
            wait(0);
        }

        // Every reply the fake has queued, delivered.
        function settle() {
            wait(20);
        }

        // ---- The pure decisions.

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

        function test_policy_clientName() {
            compare(Policy.clientName("surface-manager"), "com.webos.surfacemanager.cardshell");
            compare(Policy.clientName("org.webosports.app.settings.bluetooth"), "");
        }

        function test_policy_deviceConnected() {
            verify(!Policy.deviceConnected(null));
            verify(Policy.deviceConnected({ connected: true, connectedProfiles: [] }), "a keyboard: link up, no profile of bluetooth2's");
            verify(!Policy.deviceConnected({ connected: false, connectedProfiles: ["a2dp"] }), "the link says");
            verify(Policy.deviceConnected({ connectedProfiles: ["a2dp"] }), "a bluetooth2 without \"connected\"");
            verify(!Policy.deviceConnected({ connectedProfiles: [] }));
        }

        function test_policy_passkeyText() {
            compare(Policy.passkeyText(12345), "012345");
            compare(Policy.passkeyText(999999), "999999");
            compare(Policy.passkeyText(0), "000000");
            compare(Policy.passkeyText(undefined), "000000");
        }

        function test_policy_pairingPrompt() {
            compare(Policy.pairingPrompt({ returnValue: true, subscribed: true }, "x"), null);
            compare(Policy.pairingPrompt({ request: "incomingPairRequest", address: "a" }, ""), null);
            var p = Policy.pairingPrompt({ request: "confirmPasskey", passkey: 42 }, "aa:bb");
            compare(p.kind, "confirmation");
            compare(p.passkey, "000042");
            compare(p.address, "aa:bb", "the subscription's device when the reply has none");
            compare(Policy.pairingPrompt({ request: "authorizePairing", address: "a", name: "Phone" }, "").kind, "authorization");
            compare(Policy.pairingPrompt({ request: "enterPinCode", address: "a" }, "").kind, "pinCode");
            compare(Policy.pairingPrompt({ request: "displayPinCode", address: "a", pin: "0000" }, "").pin, "0000");
            compare(Policy.pairingPrompt({ request: "endPairing", returnValue: false }, "a").kind, "end");
        }

        function test_policy_pairOutcome() {
            compare(Policy.pairOutcome({ returnValue: true, subscribed: true }), "pending");
            compare(Policy.pairOutcome({ returnValue: true, request: "confirmPasskey" }), "pending");
            compare(Policy.pairOutcome({ returnValue: true, request: "endPairing" }), "paired");
            compare(Policy.pairOutcome({ returnValue: false, request: "endPairing", errorCode: 116 }), "failed");
            compare(Policy.pairOutcome({ returnValue: false, errorCode: 117 }), "failed", "refused up front");
            compare(Policy.pairOutcome(null), "failed");
        }

        function test_policy_replyError() {
            compare(Policy.replyError({ errorCode: 130, errorText: "x" }).error, 130);
            compare(Policy.replyError({}).error, 1, "a failure never reads as error 0");
            compare(Policy.replyError(null).error, 1);
        }

        function test_policy_deviceType() {
            // Classes from real devices, and BluezQt's answer for each.
            compare(Policy.deviceType(7078148), Policy.deviceTypes.Computer, "desktop 0x6c0104");
            compare(Policy.deviceType(0x240404), Policy.deviceTypes.Headset, "headset 0x240404");
            compare(Policy.deviceType(0x240418), Policy.deviceTypes.Headphones, "headphones 0x240418");
            compare(Policy.deviceType(0x240414), Policy.deviceTypes.AudioVideo, "loudspeaker 0x240414");
            compare(Policy.deviceType(0x5a020c), Policy.deviceTypes.Phone, "smartphone 0x5a020c");
            compare(Policy.deviceType(0x000210), Policy.deviceTypes.Modem);
            compare(Policy.deviceType(0x000540), Policy.deviceTypes.Keyboard);
            compare(Policy.deviceType(0x000580), Policy.deviceTypes.Mouse);
            compare(Policy.deviceType(0x000594), Policy.deviceTypes.Tablet);
            compare(Policy.deviceType(0x000508), Policy.deviceTypes.Joypad);
            compare(Policy.deviceType(0x000500), Policy.deviceTypes.Peripheral);
            compare(Policy.deviceType(0x000680), Policy.deviceTypes.Printer);
            compare(Policy.deviceType(0x000620), Policy.deviceTypes.Camera);
            compare(Policy.deviceType(0x000610), Policy.deviceTypes.Imaging);
            compare(Policy.deviceType(0x000704), Policy.deviceTypes.Wearable);
            compare(Policy.deviceType(0x000804), Policy.deviceTypes.Toy);
            compare(Policy.deviceType(0x000904), Policy.deviceTypes.Health);
            compare(Policy.deviceType(0x000300), Policy.deviceTypes.Network);
            compare(Policy.deviceType(0), Policy.deviceTypes.Uncategorized, "LE device, no class");
            compare(Policy.deviceType(undefined), Policy.deviceTypes.Uncategorized);
            compare(Policy.deviceRow({ address: "aa", classOfDevice: 7078148 }).Type, Policy.deviceTypes.Computer);
            compare(Policy.roleName(256 + 106), "Type", "BluezQt's TypeRole");
        }

        function test_policy_rowsKeepTheirPlace() {
            var model = Qt.createQmlObject("import QtQuick; ListModel {}", root);
            var a = { address: "aa", name: "A", paired: true };
            var b = { address: "bb", name: "B", paired: false };
            var c = { address: "cc", name: "C", paired: true };
            Policy.syncRows(model, [a, b], 0, null);
            compare(model.count, 2);
            Policy.syncRows(model, [c, b, a], 0, null);
            compare(model.get(0).Address, "aa", "a known device moved");
            compare(model.get(1).Address, "bb");
            compare(model.get(2).Address, "cc", "a new device is not last");
            Policy.syncRows(model, [c, { address: "aa", name: "A2", paired: true }], 0, null);
            compare(model.count, 2);
            compare(model.get(0).Name, "A2", "not updated in place");
            compare(model.get(1).Address, "cc");
            Policy.syncRows(model, [a, b, c], Policy.roles.Paired, /true/);
            compare(model.count, 2, "the filter on Paired");
            Policy.syncRows(model, [a, b, c], 256 + 999, /true/);
            compare(model.count, 3, "a role not offered filters nothing");
            model.destroy();
        }

        // ---- The manager.

        function test_followsTheAdapter() {
            var manager = makeManager();
            var bus = manager._bus;
            compare(manager.adapterAddress, "00:00:46:01:2a:a1");
            verify(!manager.initializing || !manager.powered);
            compare(bus.last("device/getStatus").adapterAddress, "00:00:46:01:2a:a1", "the devices of the adapter in use");
            bus.setAdapter({ powered: false });
            tryCompare(manager, "bluetoothOperational", false, 1000);
            bus.setAdapter({ powered: true, discoverable: true });
            tryCompare(manager, "discoverable", true, 1000);
        }

        function test_aServiceThatGoesAndComesBack() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setDevice(headset, { paired: true });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            manager._serviceStatus.available = false;
            verify(!manager.bluetoothOperational);
            compare(manager.devices.length, 0, "devices of a service that is gone");
            compare(bus.open("adapter/getStatus") + bus.open("device/getStatus"), 0, "subscriptions left open");
            manager._serviceStatus.available = true;
            tryCompare(manager, "bluetoothOperational", true, 1000);
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            compare(bus.open("adapter/getStatus"), 1);
            compare(bus.open("device/getStatus"), 1);
        }

        function test_deviceForAddressHasTheAdapter() {
            var manager = makeManager();
            manager._bus.setDevice(headset, { paired: true, name: "Headset" });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            var device = manager.btManager.deviceForAddress(headset.toUpperCase());
            verify(device !== null, "found by address, any case");
            compare(device.name, "Headset");
            compare(device.adapter.address, "00:00:46:01:2a:a1");
            compare(manager.btManager.deviceForAddress("00:00:00:00:00:00"), null);
        }

        function test_searchStartsWhenAListIsShown() {
            var manager = makeManager();
            var bus = manager._bus;
            compare(bus.count("adapter/startDiscovery"), 0);
            manager.discoveringMode = true;
            compare(bus.count("adapter/startDiscovery"), 1);
            bus.setAdapter({ discovering: true });
            tryCompare(manager, "discovering", true, 1000);
            manager.discoveringMode = false;
            compare(bus.count("adapter/cancelDiscovery"), 1);
        }

        function test_searchStopsByItself() {
            var manager = makeManager({ discoveryTimeoutMs: 200 });
            var bus = manager._bus;
            manager.discoveringMode = true;
            bus.setAdapter({ discovering: true });
            tryCompare(manager, "discovering", true, 1000);
            tryVerify(function () { return bus.count("adapter/cancelDiscovery") === 1; }, 2000);
            bus.setAdapter({ discovering: false });
            verify(manager.discoveringMode, "still wanted");
            wait(400);
            compare(bus.count("adapter/startDiscovery"), 1, "run again before it was asked");
            manager.searchAgain();
            compare(bus.count("adapter/startDiscovery"), 2);
        }

        function test_anAdapterTurningUpStartsTheSearch() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setAdapter({ powered: false });
            tryCompare(manager, "bluetoothOperational", false, 1000);
            manager.discoveringMode = true;
            compare(bus.count("adapter/startDiscovery"), 0);
            bus.setAdapter({ powered: true });
            tryCompare(manager, "bluetoothOperational", true, 1000);
            compare(bus.count("adapter/startDiscovery"), 1);
        }

        function test_connectingAPairedDevice() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setDevice(headset, { paired: true });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            bus.answers = { "device/connect": function () { return null; } };

            var call = manager.connectDeviceAddress(headset);
            verify(call, "no call to follow");
            compare(manager.connectingDevice.address, headset);
            compare(bus.last("device/connect").address, headset);
            compare(bus.last("device/connect").adapterAddress, "00:00:46:01:2a:a1");
            compare(bus.count("adapter/pair"), 0, "paired again");
            compare(bus.count("device/setState"), 0, "trusted before the connection was made");

            var finished = null;
            call.finished.connect(function (c) { finished = c; });
            bus.answerHeld("device/connect", { returnValue: true, address: headset });
            verify(finished !== null);
            compare(finished.error, 0);
            compare(manager.connectingDevice, null);
            compare(bus.last("device/setState").trusted, true, "the device the user picked was not trusted");
        }

        function test_aFailedConnectTrustsNothing() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setDevice(headset, { paired: true });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            bus.answers = { "device/connect": function () { return { returnValue: false, errorCode: 130, errorText: "Failed to connect with remote device" }; } };
            var call = manager.connectDeviceAddress(headset);
            var finished = null;
            call.finished.connect(function (c) { finished = c; });
            tryVerify(function () { return finished !== null; }, 1000);
            compare(finished.error, 130);
            compare(finished.errorText, "Failed to connect with remote device");
            compare(manager.connectingDevice, null);
            compare(bus.count("device/setState"), 0);
        }

        function test_aConnectedDeviceTappedIsDisconnected() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setDevice(headset, { paired: true, connected: true, connectedProfiles: ["a2dp", "hfp"] });
            tryCompare(manager, "connected", true, 1000);
            var call = manager.connectDeviceAddress(headset);
            compare(bus.count("device/connect"), 0);
            compare(bus.last("device/disconnect").address, headset);
            var finished = null;
            call.finished.connect(function (c) { finished = c; });
            tryVerify(function () { return finished !== null; }, 1000);
            compare(finished.error, 0);
        }

        function test_pairingAsksTheAgentThenConnectsAndTrusts() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            bus.setDevice(headset, { name: "Headset" });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);

            var asked = null;
            agent.requestConfirmationFromUser.connect(function (device, passkey, request) {
                asked = { device: device, passkey: passkey, request: request };
            });
            var call = manager.connectDeviceAddress(headset);
            compare(bus.open("adapter/pair"), 1);
            compare(bus.last("adapter/pair").address, headset);
            settle();
            compare(bus.count("device/connect"), 0, "connected before it was paired");

            bus.push("adapter/pair", { returnValue: true, subscribed: true, request: "confirmPasskey", passkey: 12345, adapterAddress: "00:00:46:01:2a:a1" });
            verify(asked !== null, "the user was not asked");
            compare(asked.passkey, "012345");
            compare(asked.device.name, "Headset");
            compare(asked.device.address, headset);
            asked.request.accept();
            asked.request.accept();
            asked.request.reject();
            compare(bus.count("adapter/supplyPasskeyConfirmation"), 1, "answered more than once");
            compare(bus.last("adapter/supplyPasskeyConfirmation").accept, true);
            compare(bus.last("adapter/supplyPasskeyConfirmation").address, headset);

            bus.push("adapter/pair", { returnValue: true, subscribed: false, request: "endPairing", adapterAddress: "00:00:46:01:2a:a1" });
            compare(bus.open("adapter/pair"), 0);
            compare(bus.last("device/setState").trusted, true, "a device the user paired was not trusted");
            compare(bus.last("device/connect").address, headset);
            var finished = null;
            call.finished.connect(function (c) { finished = c; });
            tryVerify(function () { return finished !== null; }, 1000);
            compare(finished.error, 0);
        }

        function test_aFailedPairingConnectsNothing() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            var cancelled = 0;
            agent.cancel.connect(function () { cancelled++; });
            bus.setDevice(speaker, {});
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            var call = manager.connectDeviceAddress(speaker);
            var finished = null;
            call.finished.connect(function (c) { finished = c; });
            settle();
            bus.push("adapter/pair", { returnValue: true, request: "enterPinCode", address: speaker });
            bus.push("adapter/pair", { returnValue: false, subscribed: false, request: "endPairing", errorCode: 116, errorText: "Pairing canceled or timed out" });
            verify(finished !== null);
            compare(finished.error, 116);
            compare(cancelled, 1, "the PIN popup was left up");
            compare(manager.connectingDevice, null);
            compare(bus.count("device/connect"), 0);
            compare(bus.count("device/setState"), 0);
        }

        function test_tappingTheDeviceBeingPairedGivesUp() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setDevice(speaker, {});
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            var call = manager.connectDeviceAddress(speaker);
            var finished = null;
            call.finished.connect(function (c) { finished = c; });
            manager.connectDeviceAddress(speaker);
            compare(bus.last("adapter/cancelPairing").address, speaker);
            compare(bus.open("adapter/pair"), 0);
            verify(finished !== null);
            verify(finished.error !== 0);
            compare(manager.connectingDevice, null);
            // The service's endPairing after the cancel connects nothing.
            bus.push("adapter/pair", { returnValue: true, request: "endPairing" });
            settle();
            compare(bus.count("device/connect"), 0);
        }

        function test_noSearchWhileConnecting() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setDevice(headset, { paired: true });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            bus.answers = { "device/connect": function () { return null; } };
            manager.discoveringMode = true;
            bus.setAdapter({ discovering: true });
            tryCompare(manager, "discovering", true, 1000);
            manager.connectDeviceAddress(headset);
            compare(bus.count("adapter/cancelDiscovery"), 1, "bluetooth2 does not pair while it searches");
            bus.setAdapter({ discovering: false });
            tryCompare(manager, "discovering", false, 1000);
            bus.answerHeld("device/connect", { returnValue: true });
            compare(bus.count("adapter/startDiscovery"), 2, "the search did not go on");
        }

        function test_searchAgainStartsOnce() {
            var manager = makeManager();
            var bus = manager._bus;
            tryVerify(function () { return manager.bluetoothOperational; }, 1000);
            bus.answers = { "adapter/startDiscovery": function () { return null; } };
            manager.searchAgain();
            settle();
            compare(bus.count("adapter/startDiscovery"), 1, "started twice before discovering came on");
            bus.answerHeld("adapter/startDiscovery", { returnValue: false, errorCode: 115 });
            manager.searchAgain();
            settle();
            compare(bus.count("adapter/startDiscovery"), 2, "a refused start kept the next one back");
        }

        function test_pairingLeavesStoppingTheSearchToBluetooth2() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setDevice(headset, { name: "Headset" });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            manager.discoveringMode = true;
            bus.setAdapter({ discovering: true });
            tryCompare(manager, "discovering", true, 1000);
            manager.connectDeviceAddress(headset);
            compare(bus.open("adapter/pair"), 1);
            settle();
            compare(bus.count("adapter/cancelDiscovery"), 0, "stopped the search as well as adapter/pair");
            bus.setAdapter({ discovering: false });
            tryCompare(manager, "discovering", false, 1000);
            settle();
            compare(bus.count("adapter/startDiscovery"), 1, "searched again while pairing");
        }

        function test_switchedOffWhileConnecting() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setDevice(headset, { paired: true });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            bus.answers = { "device/connect": function () { return null; } };
            var call = manager.connectDeviceAddress(headset);
            var finished = null;
            call.finished.connect(function (c) { finished = c; });
            bus.setAdapter({ powered: false });
            tryVerify(function () { return finished !== null; }, 1000);
            verify(finished.error !== 0);
            compare(manager.connectingDevice, null);
        }

        function test_notOperationalStartsNothing() {
            var manager = makeManager();
            manager._bus.setAdapter({ powered: false });
            tryCompare(manager, "bluetoothOperational", false, 1000);
            compare(manager.connectDeviceAddress(headset), undefined);
            compare(manager._bus.count("device/connect") + manager._bus.count("adapter/pair"), 0);
        }

        // ---- The model.

        function test_modelHasTheDevicesWithBluezQtsRoles() {
            var manager = makeManager();
            var bus = manager._bus;
            var model = makeModel(manager);
            bus.setDevice(headset, { name: "Headset", paired: true, connected: true, trusted: true });
            bus.setDevice(speaker, { name: "Speaker" });
            tryCompare(model, "count", 2, 1000);
            compare(model.get(0).Address, headset);
            compare(model.get(0).Name, "Headset");
            compare(model.get(0).FriendlyName, "Headset");
            compare(model.get(0).Paired, true);
            compare(model.get(0).Connected, true);
            compare(model.get(0).Trusted, true);
            compare(model.get(1).Paired, false);
            bus.setDevice(speaker, { paired: true });
            tryCompare(model.get(1), "Paired", true, 1000);
        }

        function test_modelFilteredOnPairedAsTheShellDoes() {
            var manager = makeManager();
            var bus = manager._bus;
            var model = makeModel(manager, { filterRole: 256 + 109, filterRegularExpression: /true/ });
            bus.setDevice(headset, { paired: true });
            bus.setDevice(speaker, { paired: false });
            tryVerify(function () { return manager.devices.length === 2; }, 1000);
            tryCompare(model, "count", 1, 1000);
            compare(model.get(0).Address, headset);
            bus.setDevice(speaker, { paired: true });
            tryCompare(model, "count", 2, 1000);
        }

        // ---- The agent, for pairings a device starts.

        function test_agentRegistersOnce() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            agent.registerToManager(manager.btManager);
            compare(bus.count("adapter/awaitPairingRequests"), 1, "bluetooth2 takes one subscriber");
            compare(bus.last("adapter/awaitPairingRequests").adapterAddress, "00:00:46:01:2a:a1");
            verify(agent.registered);
            agent.destroy();
            made = made.filter(function (o) { return o !== agent; });
            wait(0);
            compare(bus.open("adapter/awaitPairingRequests"), 0, "subscription outlived the page");
        }

        // As Settings does: the agent registered the moment the manager says
        // Bluetooth works, while the manager first hears of the adapter. The
        // adapter's address must be known by then; bluetooth2 refuses an
        // empty one (162, "Adapter address is not valid").
        function test_agentRegisteredAsBluetoothComesUpHasTheAdapter() {
            var manager = create("BluetoothManager.qml", [
                ["pragma Singleton", ""],
                ["LunaService {", "FakeBluetooth2 {"],
                ["ServiceStatus {", "FakeServiceStatus {"]
            ]);
            verify(!manager.bluetoothOperational, "operational before the adapter was heard of");
            var agent = makeAgent(manager);
            var addresses = [];
            // Not as the test ends: the agent goes before the manager.
            manager.bluetoothOperationalChanged.connect(function () {
                if (!manager.bluetoothOperational)
                    return;
                addresses.push(manager.adapterAddress);
                agent.registerToManager(manager.btManager);
            });
            tryCompare(manager, "bluetoothOperational", true, 1000);
            compare(addresses, ["00:00:46:01:2a:a1"], "adapterAddress as bluetoothOperational changed");
            var bus = manager._bus;
            compare(bus.count("adapter/awaitPairingRequests"), 1);
            compare(bus.last("adapter/awaitPairingRequests").adapterAddress, "00:00:46:01:2a:a1");
            verify(agent.registered);
        }

        function test_agentNotRegisteredWithBluetoothOff() {
            var manager = makeManager();
            var bus = manager._bus;
            bus.setAdapter({ powered: false });
            tryCompare(manager, "bluetoothOperational", false, 1000);
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            compare(bus.count("adapter/awaitPairingRequests"), 0);
            bus.setAdapter({ powered: true });
            tryCompare(manager, "bluetoothOperational", true, 1000);
            agent.registerToManager(manager.btManager);
            compare(bus.count("adapter/awaitPairingRequests"), 1);
        }

        function test_aPairingADeviceStartsIsAskedAndCanBeRefused() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            var asked = null;
            agent.requestAuthorizationFromUser.connect(function (device, request) {
                asked = { device: device, request: request };
            });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, subscribed: true, request: "incomingPairRequest", address: "bc:38:98:a8:38:64", name: "herrie-desktop" });
            compare(asked, null);
            bus.push("adapter/awaitPairingRequests", { returnValue: true, subscribed: true, request: "authorizePairing", address: "bc:38:98:a8:38:64", name: "herrie-desktop" });
            verify(asked !== null, "a Just Works pairing a device started went unasked");
            compare(asked.device.name, "herrie-desktop");
            asked.request.reject();
            compare(bus.last("adapter/supplyPasskeyConfirmation").accept, false);
            compare(bus.last("adapter/supplyPasskeyConfirmation").address, "bc:38:98:a8:38:64");
        }

        function test_aPasskeyTypedInIsSupplied() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            var request = null;
            agent.requestPasskeyFromUser.connect(function (device, r) { request = r; });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "enterPasskey", address: speaker });
            verify(request !== null);
            request.accept("004711");
            compare(bus.last("adapter/supplyPasskey").passkey, 4711);
            var pin = null;
            agent.requestPinCodeFromUser.connect(function (device, r) { pin = r; });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "enterPinCode", address: speaker });
            pin.cancel();
            compare(bus.last("adapter/cancelPairing").address, speaker);
        }

        function test_aPasskeyToShowGoesWhenThePairingEnds() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            var shown = null;
            var cancelled = 0;
            var failed = failures(agent);
            agent.displayPasskeyToUser.connect(function (device, passkey, entered) { shown = passkey; });
            agent.cancel.connect(function () { cancelled++; });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "displayPasskey", address: speaker, passkey: 7 });
            compare(shown, "000007");
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "endPairing" });
            compare(cancelled, 1);
            compare(failed.length, 0, "a pairing that ended well was said to fail");
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "endPairing" });
            compare(cancelled, 1, "cancelled with nothing on screen");
        }

        // A device's pairing nobody answered in time: BlueZ cancels it, and
        // bluetooth2 says so as pairingCanceled() does, a failed endPairing.
        // The question goes, and the agent keeps waiting for the next one.
        function test_anUnansweredIncomingPairingGoesWhenBlueZCancelsIt() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            var request = null;
            var cancelled = 0;
            agent.requestConfirmationFromUser.connect(function (device, passkey, r) { request = r; });
            agent.cancel.connect(function () { cancelled++; });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, subscribed: true, request: "confirmPasskey",
                                                       address: speaker, passkey: 998975, adapterAddress: "00:00:46:01:2a:a1" });
            verify(request !== null);
            bus.push("adapter/awaitPairingRequests", { returnValue: false, subscribed: true, request: "endPairing",
                                                       errorCode: 124, errorText: "Pairing canceled or timed out",
                                                       adapterAddress: "00:00:46:01:2a:a1" });
            compare(cancelled, 1);
            verify(agent.registered, "stopped waiting for pairing requests");
            var calls = bus.count("adapter/supplyPasskeyConfirmation");
            request.cancel();
            compare(bus.count("adapter/supplyPasskeyConfirmation"), calls, "answered a pairing that had ended");
        }

        // ---- A pairing that did not work is said, one the user refused is not.

        function failures(agent) {
            var list = [];
            agent.pairingFailed.connect(function (device, reason) { list.push({ device: device, reason: reason }); });
            return list;
        }

        function test_aFailedPairingIsReported() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.pairingTimeoutMs = 100;
            var failed = failures(agent);
            var request = null;
            agent.requestPinCodeFromUser.connect(function (device, r) { request = r; });
            bus.setDevice(speaker, { name: "Speaker" });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            manager.connectDeviceAddress(speaker);
            settle();
            bus.push("adapter/pair", { returnValue: true, request: "enterPinCode", address: speaker });
            request.accept("0000");
            bus.push("adapter/pair", { returnValue: false, subscribed: false, request: "endPairing", errorCode: 116, errorText: "Pairing canceled or timed out" });
            compare(failed.length, 1);
            compare(failed[0].device.address, speaker);
            compare(failed[0].device.name, "Speaker");
            compare(failed[0].reason, "Pairing canceled or timed out");
            wait(250);
            compare(failed.length, 1, "said twice");
        }

        function test_aPairingRefusedUpFrontIsReported() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            var failed = failures(agent);
            bus.setDevice(speaker, {});
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            manager.connectDeviceAddress(speaker);
            settle();
            bus.push("adapter/pair", { returnValue: false, errorCode: 117, errorText: "Failed to stop discovery" });
            compare(failed.length, 1);
            compare(failed[0].reason, "Failed to stop discovery");
        }

        function test_aPairingTheUserSaidNoToIsNoFailure_data() {
            return [ { tag: "reject" }, { tag: "cancel" } ];
        }
        function test_aPairingTheUserSaidNoToIsNoFailure(data) {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            var failed = failures(agent);
            var request = null;
            agent.requestConfirmationFromUser.connect(function (device, passkey, r) { request = r; });
            bus.setDevice(speaker, {});
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            manager.connectDeviceAddress(speaker);
            settle();
            bus.push("adapter/pair", { returnValue: true, request: "confirmPasskey", passkey: 1, address: speaker });
            request[data.tag]();
            bus.push("adapter/pair", { returnValue: false, subscribed: false, request: "endPairing", errorCode: 116, errorText: "Pairing canceled or timed out" });
            compare(failed.length, 0, "the user's own no was reported as a failure");

            // The next pairing failing is news again.
            manager.connectDeviceAddress(speaker);
            settle();
            bus.push("adapter/pair", { returnValue: false, subscribed: false, request: "endPairing", errorCode: 116, errorText: "Pairing canceled or timed out" });
            compare(failed.length, 1);
        }

        function test_givingUpOnAPairingIsNoFailure() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            var failed = failures(agent);
            bus.setDevice(speaker, {});
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            manager.connectDeviceAddress(speaker);
            settle();
            manager.connectDeviceAddress(speaker);  // tapped again: give up
            bus.push("adapter/pair", { returnValue: false, subscribed: false, request: "endPairing", errorCode: 116, errorText: "Pairing canceled or timed out" });
            compare(failed.length, 0);
        }

        // bluetooth2 says nothing once a device's pairing is answered, so a
        // wrong PIN shows only in the device: it drops its connection unpaired.
        function test_aDevicesPairingThatDoesNotTakeIsReported() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            var failed = failures(agent);
            var request = null;
            agent.requestPinCodeFromUser.connect(function (device, r) { request = r; });
            bus.setDevice(speaker, { name: "herrie-desktop", connected: true });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            bus.push("adapter/awaitPairingRequests", { returnValue: true, subscribed: true, request: "enterPinCode", address: speaker });
            request.accept("0000");
            settle();
            compare(failed.length, 0, "failed while still connected");
            bus.setDevice(speaker, { connected: false });
            tryVerify(function () { return failed.length === 1; }, 1000, "a wrong PIN went unsaid");
            compare(failed[0].device.name, "herrie-desktop");
            compare(failed[0].device.address, speaker);
            bus.setDevice(speaker, { connected: true });
            bus.setDevice(speaker, { connected: false });
            settle();
            compare(failed.length, 1, "said twice");
        }

        function test_aDevicesPairingThatTakesIsNoFailure() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.pairingTimeoutMs = 100;
            agent.registerToManager(manager.btManager);
            var failed = failures(agent);
            var request = null;
            agent.requestConfirmationFromUser.connect(function (device, passkey, r) { request = r; });
            bus.setDevice(speaker, { connected: true });
            tryVerify(function () { return manager.devices.length === 1; }, 1000);
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "confirmPasskey", address: speaker, passkey: 1 });
            request.accept();
            bus.setDevice(speaker, { paired: true });
            settle();
            bus.setDevice(speaker, { connected: false });
            wait(250);
            compare(failed.length, 0);
        }

        function test_aDevicesPairingNotDoneInTimeIsReported() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.pairingTimeoutMs = 100;
            agent.registerToManager(manager.btManager);
            var failed = failures(agent);
            var request = null;
            agent.requestPasskeyFromUser.connect(function (device, r) { request = r; });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "enterPasskey", address: speaker });
            request.accept("1234");
            compare(failed.length, 0);
            tryVerify(function () { return failed.length === 1; }, 1000);
            compare(failed[0].device.address, speaker);
        }

        function test_aDevicesPairingCancelledIsReportedUnlessTheUserSaidNo_data() {
            return [ { tag: "unanswered", refuse: false, expected: 1 },
                     { tag: "refused",    refuse: true,  expected: 0 } ];
        }
        function test_aDevicesPairingCancelledIsReportedUnlessTheUserSaidNo(data) {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            var failed = failures(agent);
            var request = null;
            agent.requestPinCodeFromUser.connect(function (device, r) { request = r; });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "enterPinCode", address: speaker, name: "herrie-desktop" });
            if (data.refuse)
                request.cancel();
            bus.push("adapter/awaitPairingRequests", { returnValue: false, subscribed: true, request: "endPairing",
                                                       errorCode: 124, errorText: "Pairing canceled or timed out" });
            compare(failed.length, data.expected);
            if (data.expected)
                compare(failed[0].device.name, "herrie-desktop");
            // An end with nothing asked is nobody's failure.
            bus.push("adapter/awaitPairingRequests", { returnValue: false, subscribed: true, request: "endPairing", errorCode: 124 });
            compare(failed.length, data.expected);
        }

        function test_aQuestionLeftOpenIsRefusedWithThePage() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            var request = null;
            agent.requestConfirmationFromUser.connect(function (device, passkey, r) { request = r; });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "confirmPasskey", address: speaker, passkey: 1 });
            verify(request !== null);
            agent.destroy();
            made = made.filter(function (o) { return o !== agent; });
            wait(0);
            compare(bus.last("adapter/supplyPasskeyConfirmation").accept, false, "left the device waiting");
        }

        function test_aNewQuestionReplacesTheOpenOne() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            var requests = [];
            agent.requestConfirmationFromUser.connect(function (device, passkey, r) { requests.push(r); });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "confirmPasskey", address: speaker, passkey: 1 });
            bus.push("adapter/awaitPairingRequests", { returnValue: true, request: "confirmPasskey", address: speaker, passkey: 2 });
            compare(requests.length, 2);
            requests[0].accept();
            compare(bus.count("adapter/supplyPasskeyConfirmation"), 0, "the old question answered the new one");
            requests[1].accept();
            compare(bus.count("adapter/supplyPasskeyConfirmation"), 1);
        }

        function test_agentLetGoByTheServiceRegistersAgain() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.registerToManager(manager.btManager);
            // The adapter's pairable time ran out (BT_ERR_PAIRABLE_TO).
            bus.push("adapter/awaitPairingRequests", { returnValue: false, subscribed: false, errorCode: 125 });
            verify(!agent.registered);
            agent.registerToManager(manager.btManager);
            compare(bus.count("adapter/awaitPairingRequests"), 2);
        }

        // Right after bluetoothd restarts, bluetooth2 has the adapter back
        // before it can make it pairable: it refuses the registration (123)
        // while Bluetooth stays up as the page sees it (seen on the Brax3).
        function test_aRefusedRegistrationIsTriedAgain() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.retryIntervalMs = 10;
            // As bluetooth2 does: the refusal is the subscription's only reply.
            bus.refusals = { "adapter/awaitPairingRequests": [
                { returnValue: false, subscribed: false, errorCode: 123, errorText: "Failed to make device pairable" }] };
            agent.registerToManager(manager.btManager);
            tryVerify(function () { return bus.count("adapter/awaitPairingRequests") === 2; }, 1000, "not registered again");
            settle();
            verify(agent.registered);
            compare(bus.open("adapter/awaitPairingRequests"), 1);
            wait(60);
            compare(bus.count("adapter/awaitPairingRequests"), 2, "registered again after it worked");
        }

        function test_retriesStopAfterAFew() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.retryIntervalMs = 10;
            agent.retries = 3;
            var refusal = { returnValue: false, subscribed: false, errorCode: 123 };
            bus.refusals = { "adapter/awaitPairingRequests": [refusal, refusal, refusal, refusal, refusal, refusal] };
            agent.registerToManager(manager.btManager);
            wait(200);
            compare(bus.count("adapter/awaitPairingRequests"), 4, "the first registration and three retries");
            verify(!agent.registered);
        }

        // Each time bluetoothd restarts gets its retries, not only the first.
        function test_aWorkingRegistrationGetsItsRetriesBack() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.retryIntervalMs = 10;
            agent.retries = 1;
            var refusal = { returnValue: false, subscribed: false, errorCode: 123 };
            bus.refusals = { "adapter/awaitPairingRequests": [refusal] };
            agent.registerToManager(manager.btManager);
            tryVerify(function () { return bus.count("adapter/awaitPairingRequests") === 2; }, 1000);
            settle();
            // Ended by the service again, then refused once more.
            bus.refusals = { "adapter/awaitPairingRequests": [refusal] };
            bus.push("adapter/awaitPairingRequests", { returnValue: false, subscribed: false, errorCode: 101 });
            tryVerify(function () { return bus.count("adapter/awaitPairingRequests") === 3; }, 1000,
                      "no retries left after a registration that worked");
        }

        function test_anotherClientsAgentIsLeftAlone() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.retryIntervalMs = 10;
            bus.refusals = { "adapter/awaitPairingRequests": [
                { returnValue: false, errorCode: 104, errorText: "Only one subscription allowed" }] };
            agent.registerToManager(manager.btManager);
            wait(60);
            compare(bus.count("adapter/awaitPairingRequests"), 1, "took the slot from another client");
            verify(!agent.registered);
        }

        function test_noRetryOnceBluetoothIsOff() {
            var manager = makeManager();
            var bus = manager._bus;
            var agent = makeAgent(manager);
            agent.retryIntervalMs = 50;
            agent.registerToManager(manager.btManager);
            bus.push("adapter/awaitPairingRequests", { returnValue: false, subscribed: false, errorCode: 101 });
            bus.setAdapter({ powered: false });
            tryCompare(manager, "bluetoothOperational", false, 1000);
            wait(120);
            compare(bus.count("adapter/awaitPairingRequests"), 1, "registered with Bluetooth off");
        }
    }
}
