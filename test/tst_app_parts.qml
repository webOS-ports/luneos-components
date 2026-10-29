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
import QtQuick.Controls
import QtTest
import QtCore
import LunaNext.Common 0.1
import LuneOS.Components 1.0
import LuneOS.Forms 1.0
import LuneOS.System 1.0

/*
 * The parts the Photos app brought in: ConfirmDialog's notice and ask(),
 * PromptDialog's words, check and ask(), StatusNotice's title, ArtworkScale
 * and IconToolButton's PNG sets with a pressed state, KeepScreenOn,
 * WindowFullScreen, LaunchParams' snapshot, ZoomableImage, Toast,
 * PlaceholderImage, IconListRow, SectionDivider, ListDelegateSeparator's
 * colours and the style's ToolBar colour:
 *   QT_QUICK_CONTROLS_STYLE=QtQuick.Controls.LuneOS \
 *   qmltestrunner -import modules -import test/imports -input test/tst_app_parts.qml
 */
Item {
    id: root
    width: 480
    height: 800

    readonly property url artwork: Qt.resolvedUrl("artwork/")
    readonly property url aPicture: Qt.resolvedUrl("artwork/3x/key.png")

    ConfirmDialog { id: confirm; anchors.fill: parent; visible: false }
    PromptDialog { id: prompt; anchors.fill: parent; visible: false; keyboardHeightForTest: 0 }
    StatusNotice { id: notice; width: 300; text: "The server did not answer." }

    Row {
        y: 100
        IconToolButton { id: pngKey; imageFolder: root.artwork; imageFormat: "png"; image: "key"; imageHasPressed: true; appearance: "overlay" }
        IconToolButton { id: plainPngKey; imageFolder: root.artwork; imageFormat: "png"; image: "key"; appearance: "overlay"; checkable: true }
    }

    // What KeepScreenOn and WindowFullScreen talk to
    property var calls: []
    property int cancelled: 0
    function fakeSubscribe(uri, json, onReply, onError) {
        calls.push({ uri: uri, args: JSON.parse(json) });
        return { cancel: function() { root.cancelled++; } };
    }
    KeepScreenOn { id: keep; clientName: "org.example.app"; subscribe: root.fakeSubscribe }
    QtObject {
        id: fakeWindow
        property var properties: ({})
        property string launchParams: ""
        function setWindowProperty(name, value) { var p = properties; p[name] = value; properties = p; }
    }
    WindowFullScreen { id: full; window: fakeWindow }
    LaunchParams { id: launch; window: fakeWindow; snapshotItem: notice }

    ZoomableImage { id: zoom; y: 200; width: 200; height: 150; source: root.aPicture }
    Toast { id: toast; duration: 600 }
    PlaceholderImage { id: holder; x: 220; y: 200; width: 60; height: 60; placeholder: root.aPicture }
    Column {
        y: 400
        width: 300
        SectionDivider { id: divider; text: "LIBRARIES" }
        IconListRow { id: iconRow; title: "All Photos"; subtitle: "12 photos"; iconSource: root.aPicture }
        IconListRow {
            id: pictureRow
            title: "Holiday"
            badge: root.aPicture
            busy: true
            selected: true
            picture: Component { Rectangle { objectName: "cover"; color: "red" } }
        }
        Item {
            width: 100; height: 20
            ListDelegateSeparator { id: lightLine; anchors.fill: parent; index: 0; count: 2 }
        }
        Item {
            width: 100; height: 20
            ListDelegateSeparator { id: darkLine; anchors.fill: parent; index: 0; count: 2; isHorizontal: true; lineColor: "#1a1a1a"; highlightColor: "#2e2e2e" }
        }
        ToolBar { id: defaultBar; width: 100; height: 40 }
        ToolBar { id: darkBar; width: 100; height: 40; palette.window: "#1d1d1d" }
    }

    SignalSpy { id: dividerClicks; target: divider; signalName: "clicked" }
    SignalSpy { id: zoomTaps; target: zoom; signalName: "tapped" }
    SignalSpy { id: snapshots; target: launch; signalName: "snapshotSaved" }

    TestCase {
        name: "AppParts"
        when: windowShown

        function cleanup() {
            confirm.visible = false;
            prompt.visible = false;
        }

        // The shown one of the children with that objectName
        function visibleChild(item, name) {
            if (item.objectName === name && item.visible)
                return item;
            var kids = item.children || [];
            if (item.contentItem && kids.indexOf(item.contentItem) < 0)
                kids = kids.concat([item.contentItem]);
            for (var i = 0; i < kids.length; ++i) {
                var c = visibleChild(kids[i], name);
                if (c)
                    return c;
            }
            return null;
        }

        function test_confirm_ask_runs_the_answer() {
            var ran = [];
            confirm.ask({ title: "Delete Album", message: "Sure?", acceptText: "Delete", destructive: true,
                          onAccepted: function() { ran.push("yes"); }, onRejected: function() { ran.push("no"); } });
            verify(confirm.opened);
            compare(confirm.title, "Delete Album");
            compare(findChild(confirm, "confirmAcceptButton").text, "Delete");
            verify(Qt.colorEqual(findChild(confirm, "confirmAcceptButton").color, "#be0003"));
            confirm.accepted();
            compare(ran, ["yes"]);
            verify(!confirm.opened, "closed before the answer ran");
            // A second ask resets what the first set
            confirm.ask({ message: "Again?", onRejected: function() { ran.push("no"); } });
            compare(confirm.title, "");
            compare(confirm.acceptText, "OK");
            verify(!confirm.destructive);
            confirm.rejected();
            compare(ran, ["yes", "no"]);
            // Not asked: the signals alone, the dialog left to its user
            confirm.open();
            confirm.accepted();
            verify(confirm.opened);
            compare(ran, ["yes", "no"]);
        }

        function test_confirm_notice_has_one_button() {
            confirm.ask({ title: "Sync failed", rejectText: "" });
            verify(findChild(confirm, "confirmAcceptButton").visible);
            verify(!findChild(confirm, "confirmRejectButton").visible, "no blank second button");
            confirm.ask({ title: "Two" });
            verify(findChild(confirm, "confirmRejectButton").visible);
        }

        function test_prompt_ask_selects_and_checks() {
            var got = [];
            prompt.ask({ title: "Rename Album", text: "Holiday", acceptText: "Rename",
                         valid: function(t) { return t.trim() !== ""; },
                         onAccepted: function(t) { got.push(t); } });
            verify(prompt.opened);
            verify(prompt.keepClearOfKeyboard, "clear of the keyboard by default");
            compare(findChild(prompt, "promptAcceptButton").text, "Rename");
            compare(findChild(prompt, "promptRejectButton").text, "Cancel");
            compare(prompt.field.textInput.selectedText, "Holiday", "the text selected on opening");
            // The field under the title, not over it
            var title = prompt.field.parent.parent.parent.children[0];
            waitForItemPolished(prompt.field.parent.parent);
            var titleFoot = title.mapToItem(root, 0, title.height).y;
            verify(prompt.field.mapToItem(root, 0, 0).y >= titleFoot,
                   "field at " + prompt.field.mapToItem(root, 0, 0).y + ", title ends at " + titleFoot);
            prompt.message = "Say what it is called";
            var message = prompt.field.parent.parent.parent.children[1];
            waitForItemPolished(prompt.field.parent.parent);
            verify(prompt.field.mapToItem(root, 0, 0).y >= message.mapToItem(root, 0, message.height).y,
                   "and under a message");
            prompt.message = "";
            // Refused: not taken, still open
            prompt.text = "   ";
            prompt.accept();
            verify(prompt.opened);
            compare(got, []);
            prompt.text = "Summer";
            prompt.accept();
            compare(got, ["Summer"]);
            verify(!prompt.opened);
        }

        function test_prompt_signals_and_reject() {
            var rejected = 0;
            prompt.ask({ onRejected: function() { rejected++; } });
            compare(prompt.text, "");
            compare(prompt.acceptText, "OK");
            prompt.reject();
            compare(rejected, 1);
            verify(!prompt.opened);
            // Not asked, anything is taken and the signal says so
            var spy = signalSpy.createObject(root, { target: prompt, signalName: "accepted" });
            prompt.open();
            prompt.text = "";
            prompt.accept();
            compare(spy.count, 1);
            compare(spy.signalArguments[0][0], "");
            spy.destroy();
        }

        function test_notice_title() {
            var title = findChild(notice, "noticeTitle");
            verify(!title.visible, "no title, no line for it");
            var words = title.parent;
            var before = words.implicitHeight;
            notice.title = "Sync failed";
            verify(title.visible);
            tryVerify(function() { return words.implicitHeight > before; }, 1000, "the title takes a line above the text");
            notice.title = "";
            var dismissed = signalSpy.createObject(root, { target: notice, signalName: "dismissed" });
            mouseClick(findChild(notice, "noticeCloseButton"));
            compare(dismissed.count, 1, "the close key dismisses it");
            dismissed.destroy();
        }

        function test_artwork_scale() {
            compare(ArtworkScale.scale(10), 1);
            compare(ArtworkScale.scale(10.4), 1);
            compare(ArtworkScale.scale(11), 2);
            compare(ArtworkScale.scale(20.4), 2);
            compare(ArtworkScale.scale(21), 3);
            compare(ArtworkScale.scale(40), 3);
            compare(ArtworkScale.scale(5), 1);
            compare(ArtworkScale.url("file:///a/images", "k", 16), "file:///a/images/2x/k.png");
            compare(ArtworkScale.url("file:///a/images/", "k", 10), "file:///a/images/1x/k.png");
        }

        function test_png_key_and_its_pressed_state() {
            var set = ArtworkScale.scale(Units.gridUnit) + "x/";
            var img = visibleChild(pngKey, "iconButtonImage");
            verify(img !== null);
            compare(String(img.source), String(root.artwork) + set + "key.png");
            tryCompare(img, "status", Image.Ready);
            mousePress(pngKey);
            compare(String(img.source), String(root.artwork) + set + "key-pressed.png");
            tryCompare(img, "status", Image.Ready);
            verify(!pngKey.background.lit, "the picture is the light, not the key");
            mouseRelease(pngKey);
            compare(String(img.source), String(root.artwork) + set + "key.png");
            // Without a pressed state: the same picture, the key lit
            plainPngKey.checked = true;
            compare(String(visibleChild(plainPngKey, "iconButtonImage").source), String(root.artwork) + set + "key.png");
            verify(plainPngKey.background.lit);
            plainPngKey.checked = false;
        }

        function test_keep_screen_on() {
            calls = [];
            cancelled = 0;
            verify(!keep.blocked);
            keep.active = true;
            verify(keep.blocked);
            compare(calls.length, 1);
            compare(calls[0].uri, "luna://com.palm.display/control/setProperty");
            compare(calls[0].args, { requestBlock: true, client: "org.example.app" });
            keep.active = true;
            compare(calls.length, 1, "one call while it stays on");
            keep.active = false;
            verify(!keep.blocked);
            compare(cancelled, 1);
        }

        function test_window_full_screen() {
            full.active = true;
            compare(fakeWindow.properties["LuneOS_fullscreen"], "true");
            full.active = false;
            compare(fakeWindow.properties["LuneOS_fullscreen"], "false");
        }

        function test_launch_snapshot() {
            var dir = String(StandardPaths.writableLocation(StandardPaths.TempLocation)).replace(/^file:\/\//, "");
            var path = dir + "/tst_app_parts-" + Date.now() + ".png";
            snapshots.clear();
            fakeWindow.launchParams = JSON.stringify({ snapshot: path });
            tryCompare(snapshots, "count", 1);
            compare(snapshots.signalArguments[0][0], path);
            // A relative path is not written anywhere
            fakeWindow.launchParams = JSON.stringify({ snapshot: "relative.png" });
            wait(100);
            compare(snapshots.count, 1);
        }

        function test_zoomable_image() {
            tryCompare(zoom, "status", Image.Ready);
            verify(!zoom.zoomed);
            zoomTaps.clear();
            mouseClick(zoom);
            tryCompare(zoomTaps, "count", 1);
            mouseDoubleClickSequence(zoom);
            tryVerify(function() { return zoom.zoomed; });
            compare(zoomTaps.count, 1, "a double tap is not a tap");
            // Zoomed in, it is dragged about
            var x = zoom.contentX, y = zoom.contentY;
            mouseDrag(zoom, zoom.width / 2, zoom.height / 2, -60, -40);
            tryVerify(function() { return zoom.contentX !== x || zoom.contentY !== y; }, 1000, "dragged");
            mouseDoubleClickSequence(zoom);
            tryVerify(function() { return !zoom.zoomed; });
        }

        function test_toast() {
            verify(!toast.visible);
            toast.show("Wallpaper set");
            verify(toast.visible, "shown at once, fading in");
            compare(findChild(toast, "toast").text, "Wallpaper set");
            tryCompare(toast, "opacity", 1, 1000);
            // Gone from showing, still there while it fades
            tryCompare(toast, "showing", false, 2000);
            verify(toast.visible && toast.opacity > 0, "fading out, not cut off");
            tryCompare(toast, "visible", false, 1000);
            compare(toast.opacity, 0);
            // Without a fade it comes and goes at once
            toast.fadeDuration = 0;
            toast.show("Copied");
            compare(toast.opacity, 1);
            tryCompare(toast, "showing", false, 2000);
            verify(!toast.visible);
            toast.fadeDuration = 250;
        }

        function test_placeholder_image() {
            var sign = findChild(holder, "placeholder");
            verify(sign.visible, "the sign while there is no picture");
            var broken = signalSpy.createObject(root, { target: holder, signalName: "broken" });
            ignoreWarning(/Cannot open: .*missing\.png/);
            holder.source = Qt.resolvedUrl("artwork/missing.png");
            tryCompare(broken, "count", 1);
            verify(sign.visible);
            holder.source = root.aPicture;
            tryCompare(holder, "status", Image.Ready);
            verify(!sign.visible);
            broken.destroy();
        }

        function test_icon_list_row() {
            compare(findChild(iconRow, "rowTitle").text, "All Photos");
            verify(findChild(iconRow, "rowSubtitle").visible);
            verify(findChild(iconRow, "rowIcon").visible);
            verify(!findChild(iconRow, "rowBadge").visible);
            verify(!findChild(iconRow, "rowBusy").visible);
            // A picture in the icon's place, a badge, busy and selected
            verify(!findChild(pictureRow, "rowIcon").visible);
            tryVerify(function() { return findChild(pictureRow, "cover") !== null; });
            verify(findChild(pictureRow, "rowBadge").visible);
            verify(findChild(pictureRow, "rowBusy").visible);
            verify(!findChild(pictureRow, "rowSubtitle").visible, "no subtitle, no line");
            verify(Qt.colorEqual(pictureRow.background.color, "#3c4a57"));
            verify(Qt.colorEqual(iconRow.background.color, "transparent"));
        }

        function test_section_divider() {
            dividerClicks.clear();
            compare(findChild(divider, "dividerLabel").text, "LIBRARIES");
            mouseClick(divider);
            compare(dividerClicks.count, 1);
        }

        function test_separator_colours() {
            var light = lightLine.children[0];
            verify(Qt.colorEqual(light.color, "#ADADAD"));
            verify(light.visible);
            verify(Qt.colorEqual(lightLine.children[1].color, "#ECECEC"));
            lightLine.highlightColor = "#2e2e2e";
            verify(Qt.colorEqual(lightLine.children[1].color, "#2e2e2e"));
            lightLine.highlightColor = "#ECECEC";
            var dark = darkLine.children[2];
            verify(dark.visible);
            verify(Qt.colorEqual(dark.color, "#1a1a1a"));
            verify(Qt.colorEqual(darkLine.children[3].color, "#2e2e2e"));
            compare(dark.height, darkLine.height, "the vertical line is as tall as the row");
            compare(dark.width, 1);
        }

        function test_toolbar_colour() {
            verify(Qt.colorEqual(defaultBar.background.color, "#343434"));
            verify(Qt.colorEqual(darkBar.background.color, "#1d1d1d"));
        }
    }

    Component { id: signalSpy; SignalSpy {} }
}
