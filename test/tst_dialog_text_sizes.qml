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

        // Dialog's 16 px title, its 12pt message and a 12pt box label.
        function test_unset_they_keep_their_sizes() {
            var d = createTemporaryObject(plainDialog, page);
            compare(d.titlePixelSize, 16);
            compare(d.messagePixelSize, px("12pt"));
            var b = createTemporaryObject(plainBox, page);
            compare(b.labelPixelSize, px("12pt"));
        }

        function test_messagePixelSize_sizes_the_message() {
            var d = createTemporaryObject(plainDialog, page, { messagePixelSize: px("medium") });
            compare(textShowing(d, "m").font.pixelSize, px("medium"));
            compare(textShowing(d, "t").font.pixelSize, 16);
        }

        function test_labelPixelSize_sizes_the_label() {
            var b = createTemporaryObject(plainBox, page, { labelPixelSize: px("medium") });
            compare(textShowing(b, "c").font.pixelSize, px("medium"));
        }
    }
}
