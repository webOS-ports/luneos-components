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
 * Dialog's messagePixelSize and DialogCheckBox's labelPixelSize, next to
 * titlePixelSize: unset they keep the sizes these always had, set they size
 * the text they name:
 *   qmltestrunner -import modules -import test/imports -input test/tst_dialog_text_sizes.qml
 */
Item {
    id: page
    width: 480
    height: 800

    Component {
        id: plainDialog
        Dialog { title: "t"; message: "m" }
    }

    Component {
        id: plainBox
        DialogCheckBox { text: "c" }
    }

    TestCase {
        name: "DialogTextSizes"
        when: windowShown

        function px(size) {
            return Math.round(FontUtils.sizeToPixels(size));
        }

        function textShowing(item, s) {
            var found = null;
            (function walk(i) {
                if (found)
                    return;
                if (i.text === s && i.font !== undefined)
                    found = i;
                for (var k = 0; k < i.children.length; k++)
                    walk(i.children[k]);
            })(item);
            verify(found !== null, "no text \"" + s + "\"");
            return found;
        }

        // Dialog's 2 gu title (Enyo's 20px caption), its 12pt message and a
        // 12pt box label.
        function test_unset_they_keep_their_sizes() {
            var d = createTemporaryObject(plainDialog, page);
            compare(d.titlePixelSize, Units.gu(2.0));
            compare(d.messagePixelSize, px("12pt"));
            var b = createTemporaryObject(plainBox, page);
            compare(b.labelPixelSize, px("12pt"));
        }

        function test_messagePixelSize_sizes_the_message() {
            var d = createTemporaryObject(plainDialog, page, { messagePixelSize: px("medium") });
            compare(textShowing(d, "m").font.pixelSize, px("medium"));
            compare(textShowing(d, "t").font.pixelSize, Units.gu(2.0));
        }

        // As Enyo's ModalDialog caption: larger than the message, not bold,
        // the body's #333, and a long one wraps rather than being cut short.
        function test_title_reads_as_legacy_webOS_caption() {
            var d = createTemporaryObject(plainDialog, page);
            var t = textShowing(d, "t");
            verify(t.font.pixelSize > textShowing(d, "m").font.pixelSize, "the title is larger than the message");
            verify(t.font.weight < Font.DemiBold, "the title is not bold");
            compare(t.color, Qt.color("#333333"));
            compare(t.wrapMode, Text.Wrap);
        }

        function test_labelPixelSize_sizes_the_label() {
            var b = createTemporaryObject(plainBox, page, { labelPixelSize: px("medium") });
            compare(textShowing(b, "c").font.pixelSize, px("medium"));
        }
    }
}
