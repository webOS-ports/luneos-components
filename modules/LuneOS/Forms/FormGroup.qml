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

import LuneOS.Forms 1.0

/*
 * A titled group of rows - the style's GroupBox - that draws the rule
 * between one row and the next itself:
 *
 *     FormGroup {
 *         title: "Picture"
 *         LabelAndSwitch { label: "HDR"; visible: hdrSupported }
 *         LabelAndSwitch { label: "Zero shutter lag" }
 *     }
 *
 * Only rows that are visible count, and there is none after the last row:
 * the group's own edge closes it off. Phone's and Camera's preference groups
 * worked this way; Settings places a HorizontalSeparator between its rows by
 * hand, which still works inside a plain GroupBox.
 */
GroupBox {
    id: group

    default property alias rows: rowsColumn.data

    width: parent ? parent.width : implicitWidth

    Item {
        width: parent ? parent.width : implicitWidth
        implicitWidth: rowsColumn.implicitWidth
        implicitHeight: rowsColumn.height
        height: implicitHeight

        Column {
            id: rowsColumn
            width: parent.width
        }

        Repeater {
            model: rowsColumn.children.length

            delegate: HorizontalSeparator {
                required property int index
                readonly property Item row: rowsColumn.children[index]

                readonly property bool shown: !!row && row.visible && row.height > 0
                readonly property bool lastShown: {
                    for (var i = index + 1; i < rowsColumn.children.length; ++i) {
                        var other = rowsColumn.children[i];
                        if (other && other.visible && other.height > 0)
                            return false;
                    }
                    return true;
                }

                width: rowsColumn.width
                y: row ? row.y + row.height - 1 : 0
                visible: shown && !lastShown
            }
        }
    }
}
