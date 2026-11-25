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
import LunaNext.Common 0.1

/*
 * One line of text that scrolls when it is wider than its width, instead of
 * being cut short: a song title or artist on a player.
 *
 *   MarqueeText { width: parent.width; text: track.title; color: "white" }
 *
 * Text that fits stands still. Longer text waits (pause), slides left until
 * its end shows, at speed pixels a second, waits again and jumps back to
 * its start, as long as running is true; set running to false while the item
 * cannot be seen to keep it from waking the GPU. A new text, or a new width,
 * starts again from the beginning.
 *
 * color, font and horizontalAlignment are the line's; horizontalAlignment
 * only matters for text that fits.
 */
Item {
    id: marquee

    property string text
    property color color: "black"
    property alias font: label.font
    property int horizontalAlignment: Text.AlignLeft
    property bool running: visible
    // Pixels a second, and the wait at each end in milliseconds.
    property real speed: Units.gu(3)
    property int pause: 2000

    // How far the text is wider than the line: 0 when it fits.
    readonly property real overflow: Math.max(0, Math.ceil(label.implicitWidth - width))
    readonly property bool scrolling: overflow > 0 && running

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    clip: overflow > 0

    Text {
        id: label
        objectName: "marqueeLabel"
        width: marquee.overflow > 0 ? implicitWidth : marquee.width
        text: marquee.text
        color: marquee.color
        horizontalAlignment: marquee.overflow > 0 ? Text.AlignLeft : marquee.horizontalAlignment
        wrapMode: Text.NoWrap
        maximumLineCount: 1
        textFormat: Text.PlainText
    }

    SequentialAnimation {
        id: slide
        loops: Animation.Infinite
        running: marquee.scrolling
        PauseAnimation { duration: marquee.pause }
        NumberAnimation {
            target: label
            property: "x"
            from: 0
            to: -marquee.overflow
            duration: Math.max(1, marquee.overflow / Math.max(1, marquee.speed) * 1000)
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: marquee.pause }
        PropertyAction { target: label; property: "x"; value: 0 }
    }

    function restart() {
        label.x = 0;
        if (slide.running)
            slide.restart();
    }
    onTextChanged: restart()
    onWidthChanged: restart()
    onScrollingChanged: if (!scrolling) label.x = 0
}
