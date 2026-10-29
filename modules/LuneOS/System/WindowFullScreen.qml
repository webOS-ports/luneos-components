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

import QtQuick 2.12

/*
 * The app's card full screen while active, over the status bar and the
 * gesture area too: luna-next-cardshell makes a card full screen while its
 * window property "LuneOS_fullscreen" is "true" (CardWindowWrapper); a
 * flick up from the bottom edge still leaves it. A shell without this
 * ignores the property.
 *
 *   WindowFullScreen { window: appWindow; active: pictureView.isOpen }
 */
QtObject {
    // The app's window (a WebOSWindow, or anything with setWindowProperty)
    property var window: null
    property bool active: false

    onActiveChanged: _apply()
    onWindowChanged: _apply()
    Component.onCompleted: _apply()

    function _apply() {
        if (window && typeof window.setWindowProperty === "function")
            window.setWindowProperty("LuneOS_fullscreen", active ? "true" : "false");
    }
}
