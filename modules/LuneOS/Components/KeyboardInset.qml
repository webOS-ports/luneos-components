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

/*
 * How much of an item the on-screen keyboard covers, for a dialog or popup
 * that has to stay above it:
 *
 *   KeyboardInset { id: keyboard; item: page }
 *   y: Math.max(0, (keyboard.top - height) / 2)
 *
 * keyboardRectangle is in window coordinates, so its top is mapped into the
 * item. An input method that says it is showing but gives no rectangle has
 * the lower 45% of the item kept free. With no on-screen keyboard (none
 * showing, or a hardware one) top is the item's height and height is 0.
 */
QtObject {
    id: inset

    property Item item

    // For tests, which have no keyboard: the height of one to lay out for,
    // when not negative.
    property real heightForTest: -1

    // Where the keyboard starts, in the item's coordinates.
    readonly property real top: {
        if (!item)
            return 0;
        if (heightForTest >= 0)
            return Math.max(0, item.height - heightForTest);
        var kb = Qt.inputMethod.keyboardRectangle;
        if (!Qt.inputMethod.visible)
            return item.height;
        if (kb.height <= 0)
            return item.height * 0.55;
        return Math.max(0, Math.min(item.height, item.mapFromItem(null, 0, kb.y).y));
    }

    // The part of the item it covers.
    readonly property real height: item ? item.height - top : 0
}
