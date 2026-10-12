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

import QtQuick 2.9
import QtQuick.Controls 2.2
// Drawn by the LuneOS style even in an app that runs with Qt's default
// style (Phone does): these are the platform's rows, not the app's
import QtQuick.Controls.LuneOS 2.0
// Units & font sizes
import LunaNext.Common 0.1
import LuneOS.Forms 1.0

/*
 * A text field for a light page or popup: white, rounded, a thin grey edge.
 *
 * The style's TextField is drawn for the dark input art, and on the light
 * group boxes it came out as a dark smudge, so each app replaced its
 * background with this same rectangle - Settings alone pasted it into
 * fifteen fields.
 *
 * "acceptable" turns the edge red. It belongs to the field rather than the
 * page, so a field cannot be left looking valid while the button that
 * depends on it is disabled.
 */
TextField {
    id: field

    property bool acceptable: true

    color: Colors.text
    leftPadding: Units.gu(1)
    rightPadding: Units.gu(1)

    background: Rectangle {
        color: field.enabled ? Colors.fieldBackground : Colors.fieldDisabledBackground
        radius: Units.gu(0.6)
        border.color: field.acceptable ? Colors.fieldBorder : Colors.error
        border.width: 1
    }
}
