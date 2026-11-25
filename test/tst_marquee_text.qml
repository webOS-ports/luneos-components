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

/*
 * MarqueeText: a line that fits stands still, a longer one scrolls to its
 * end and back to its start, and a new text starts over.
 *
 *   qmltestrunner -import modules -import test/imports -input test/tst_marquee_text.qml
 */

import QtQuick
import QtTest
import LunaNext.Common 0.1
import LuneOS.Components 1.0

Item {
    id: page
    width: 480
    height: 200

    MarqueeText {
        id: marquee
        width: 200
        // Fast, with short waits, so a whole round fits in a test.
        speed: 2000
        pause: 50
        font.pixelSize: 20
    }

    TestCase {
        name: "MarqueeText"
        when: windowShown

        function label() {
            for (var i = 0; i < marquee.children.length; i++)
                if (marquee.children[i].objectName === "marqueeLabel")
                    return marquee.children[i];
            return null;
        }

        function test_a_line_that_fits_stands_still() {
            marquee.text = "Ghosts";
            compare(marquee.overflow, 0);
            verify(!marquee.scrolling);
            verify(!marquee.clip);
            wait(200);
            compare(label().x, 0);
        }

        function test_a_long_line_scrolls_to_its_end_and_back() {
            marquee.text = "Blood on the Dance Floor: HIStory in the Mix (Remastered Deluxe Edition)";
            verify(marquee.overflow > 0);
            verify(marquee.scrolling);
            verify(marquee.clip);
            // waits first, at its start
            compare(label().x, 0);
            // then shows its end
            tryCompare(label(), "x", -marquee.overflow, 3000);
            // and goes back to its start
            tryCompare(label(), "x", 0, 3000);
        }

        function test_a_new_text_starts_over() {
            marquee.text = "Michael Jackson, Janet Jackson, The Jacksons and friends";
            tryVerify(function() { return label().x < 0; }, 3000);
            marquee.text = "Michael Jackson, Janet Jackson, The Jacksons and others";
            compare(label().x, 0);
        }

        function test_not_running_stands_still_at_its_start() {
            marquee.text = "Michael Jackson, Janet Jackson, The Jacksons and friends";
            tryVerify(function() { return label().x < 0; }, 3000);
            marquee.running = false;
            compare(label().x, 0);
            verify(!marquee.scrolling);
            wait(200);
            compare(label().x, 0);
            marquee.running = true;
        }

        function test_alignment_only_for_a_line_that_fits() {
            marquee.horizontalAlignment = Text.AlignHCenter;
            marquee.text = "Ghosts";
            compare(label().horizontalAlignment, Text.AlignHCenter);
            marquee.text = "Blood on the Dance Floor: HIStory in the Mix (Remastered Deluxe Edition)";
            compare(label().horizontalAlignment, Text.AlignLeft);
            marquee.horizontalAlignment = Text.AlignLeft;
        }
    }
}
