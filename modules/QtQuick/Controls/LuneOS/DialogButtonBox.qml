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
import QtQuick.Templates 2.12 as T

import QtQuick.Controls.LuneOS 2.0
import LunaNext.Common 0.1

/*
 * The buttons a Dialog makes from standardButtons. Basic's version built them
 * from Basic's Button; these are LuneOS buttons, coloured by what they do the
 * way the apps colour their own: accepting is green, destroying is red.
 */
T.DialogButtonBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            (control.count === 1 ? implicitContentWidth * 2 : implicitContentWidth)
                            + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    spacing: Units.gu(1)
    padding: 25
    topPadding: Units.gu(1)
    alignment: count === 1 ? Qt.AlignRight : undefined

    delegate: Button {
        width: control.count === 1 ? control.availableWidth / 2 : undefined
        LuneOSButton.mainColor: {
            switch (T.DialogButtonBox.buttonRole) {
            case T.DialogButtonBox.AcceptRole:
            case T.DialogButtonBox.YesRole:
            case T.DialogButtonBox.ApplyRole:
                return LuneOSButton.affirmativeColor;
            case T.DialogButtonBox.DestructiveRole:
                return LuneOSButton.negativeColor;
            default:
                return LuneOSButton.secondaryColor;
            }
        }
    }

    contentItem: ListView {
        implicitWidth: contentWidth
        model: control.contentModel
        spacing: control.spacing
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        snapMode: ListView.SnapToItem
    }

    // The dialog's own art shows through.
    background: Item { }
}
