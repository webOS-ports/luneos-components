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
import LunaNext.Common 0.1
import LuneOS.Components 1.0

/*
 * Where a Dialog's content sits in its frame, as legacy webOS's ModalDialog
 * had it (2 gu inside the frame image, 1 gu clear of its visible edge), and
 * a frame never shorter than its content:
 *   qmltestrunner -import modules -import test/imports -input test/tst_dialog_frame.qml
 */
Item {
    id: page
    width: 480
    height: 800

    Dialog {
        id: dialog
        visible: false
        title: "Delete Album"
        message: "Are you sure you want to delete this album? It cannot be undone."
        dialogHeight: Units.gu(30)
        dialogWidth: Units.gu(30)
        DialogButton {
            objectName: "frameButton"
            text: "Delete"
            buttonWidth: Units.gu(26)
        }
    }

    // A height guessed too small for what it holds.
    Dialog {
        id: tight
        visible: false
        title: "Delete"
        message: "This permanently deletes the selected photos from your cloud account. It can't be undone."
        dialogHeight: Units.gu(8)
        dialogWidth: Units.gu(30)
        DialogButton { objectName: "tightFirst"; text: "Delete"; buttonWidth: Units.gu(26) }
        DialogButton { text: "Cancel"; buttonWidth: Units.gu(26) }
    }

    // Kept clear of the keyboard, compact: its compact height is kept.
    Dialog {
        id: compactOne
        visible: false
        title: "Clear"
        keepClearOfKeyboard: true
        dialogHeight: 600
        compactDialogHeight: Units.gu(15)
        dialogWidth: Units.gu(30)
        DialogButton { text: "OK"; buttonWidth: Units.gu(26) }
    }

    // Compact, with more in it than its compact height and the room above
    // the keyboard hold.
    Dialog {
        id: compactTight
        visible: false
        title: "Delete"
        message: "This permanently deletes the selected photos from your cloud account."
        keepClearOfKeyboard: true
        dialogHeight: 600
        compactDialogHeight: Units.gu(6)
        dialogWidth: Units.gu(30)
        DialogButton { text: "Delete"; buttonWidth: Units.gu(26) }
    }

    TestCase {
        name: "DialogFrame"
        when: windowShown

        function cleanup() {
            dialog.close();
            tight.close();
            compactOne.close();
            compactOne.keyboardHeightForTest = -1;
            compactTight.close();
            compactTight.keyboardHeightForTest = -1;
        }

        // The frame: the item the corner images are drawn in.
        function frameOf(d) {
            var found = null;
            function walk(it) {
                if (found)
                    return;
                if (it.source !== undefined && String(it.source).indexOf("dialog-left-top.png") >= 0) {
                    found = it.parent;
                    return;
                }
                for (var i = 0; i < it.children.length; i++)
                    walk(it.children[i]);
            }
            walk(d);
            verify(found !== null, "the frame");
            return found;
        }

        function textOf(d, text) {
            var found = null;
            function walk(it) {
                if (!found && it.text === text && it.font !== undefined)
                    found = it;
                for (var i = 0; i < it.children.length && !found; i++)
                    walk(it.children[i]);
            }
            walk(d);
            verify(found !== null, text);
            return found;
        }

        // Enyo 1.0's ModalDialog: content 20 px inside dialog.png, which is
        // 2 gu at the frame's 0.1 gu a pixel; its outer 10 px (1 gu) are
        // shadow, so the words are 1 gu clear of the visible edge.
        function test_content_sits_as_legacy_put_it() {
            dialog.open();
            compare(dialog.contentInset, Units.gu(2));
            var frame = frameOf(dialog);
            var f = frame.mapToItem(page, 0, 0);
            var title = textOf(dialog, dialog.title);
            var message = textOf(dialog, dialog.message);
            var t = title.mapToItem(page, 0, 0);
            var m = message.mapToItem(page, 0, 0);
            fuzzyCompare(t.y - f.y, Units.gu(2), 1, "title from the frame's top");
            fuzzyCompare(m.x - f.x, Units.gu(2), 1, "message from the frame's left");
            fuzzyCompare((f.x + frame.width) - (m.x + message.width), Units.gu(2), 1,
                         "message from the frame's right");
            // 1 gu of shadow, then 1 gu clear of the visible edge.
            fuzzyCompare(m.x - (f.x + Units.gu(1)), Units.gu(1), 1, "clear of the visible edge");
            compare(dialog.contentWidth, dialog.dialogWidth - Units.gu(4));
            compare(message.width, dialog.contentWidth);
            var b = findChild(dialog, "frameButton");
            var bb = b.mapToItem(page, 0, b.height);
            fuzzyCompare((f.y + frame.height) - bb.y, Units.gu(2) + Units.gu(1), 1,
                         "the last button 1 gu above the content's foot");
        }

        // A dialog with room to spare keeps the height it asked for.
        function test_a_roomy_dialog_keeps_its_height() {
            dialog.open();
            verify(dialog.fittedHeight < dialog.dialogHeight);
            compare(dialog.frameHeight, dialog.dialogHeight);
            compare(frameOf(dialog).height, dialog.dialogHeight);
        }

        // One asked too small grows to its content rather than drawing its
        // buttons over its message.
        function test_a_tight_dialog_grows_to_its_content() {
            tight.open();
            verify(tight.fittedHeight > tight.dialogHeight);
            compare(tight.frameHeight, tight.fittedHeight);
            compare(frameOf(tight).height, tight.fittedHeight);
            var message = textOf(tight, tight.message);
            var first = findChild(tight, "tightFirst");
            // The 1 gu the dialog keeps between its message and its own
            // contents, as it does in a roomy one.
            fuzzyCompare(first.mapToItem(page, 0, 0).y - message.mapToItem(page, 0, message.height).y,
                         Units.gu(1), 1, "1 gu between the message and the buttons");
        }

        // Above the keyboard the compact height is the one drawn, when the
        // content fits in it.
        function test_compact_keeps_its_height() {
            compactOne.keyboardHeightForTest = 400;
            compactOne.open();
            verify(compactOne.compact);
            verify(compactOne.fittedHeight <= compactOne.compactDialogHeight);
            compare(frameOf(compactOne).height, compactOne.compactDialogHeight);
        }

        // Grown past the room above the keyboard, the dialog is as tall as
        // its frame, so the frame is not cut off at its top.
        function test_a_grown_compact_frame_is_all_shown() {
            compactTight.keyboardHeightForTest = page.height - Units.gu(10);
            compactTight.open();
            verify(compactTight.compact);
            verify(compactTight.fittedHeight > Units.gu(10), "more than the room above the keyboard");
            compare(frameOf(compactTight).height, compactTight.fittedHeight);
            verify(compactTight.height >= compactTight.frameHeight,
                   "dialog " + compactTight.height + " frame " + compactTight.frameHeight);
            var f = frameOf(compactTight).mapToItem(page, 0, 0);
            verify(f.y >= 0, "the frame's top on the page: " + f.y);
        }
    }
}
