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

import LunaNext.Common 0.1

/*
 * Without this a Dialog fell back to the Basic style: a white box with a
 * small grey title and Basic's own buttons, sat next to LuneOS popups drawn
 * on the dialog art. It now looks like one of those popups, with the title
 * in the bold centred line the apps were already writing by hand.
 *
 * Placed like the style's Popup: on the window overlay and centred, so a
 * Dialog declared inside a page is not squeezed under the page's header.
 */
T.Dialog {
    id: control

    parent: T.Overlay.overlay
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    // Narrower than the screen: a Dialog lays its title and buttons out to its
    // own width and its text wraps, so only the width is capped. Capping the
    // height would push the buttons out of the box instead.
    width: parent ? Math.min(implicitWidth, parent.width - Units.gu(4)) : implicitWidth

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding,
                            implicitHeaderWidth,
                            implicitFooterWidth)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    // The same 25px as the style's Popup: the width of the dialog art's frame.
    padding: 25
    topPadding: header && header.visible ? Units.gu(1) : 25
    bottomPadding: footer && footer.visible ? Units.gu(1) : 25

    font.family: "Prelude"
    font.pixelSize: FontUtils.sizeToPixels("medium")
    font.weight: Font.Light

    background: BorderImage {
        source: "images/dialog-bg.png"
        border.left: 25; border.top: 25
        border.right: 25; border.bottom: 25
    }

    header: T.Label {
        text: control.title
        visible: control.title !== ""
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        topPadding: 25
        leftPadding: 25
        rightPadding: 25
        font.family: "Prelude"
        font.pixelSize: FontUtils.sizeToPixels("18pt")
        font.weight: Font.Bold
        color: "#2a2929"
    }

    footer: DialogButtonBox {
        visible: count > 0
    }
}
