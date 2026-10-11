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

// Theme specific properties
import QtQuick.Controls.LuneOS 2.0
// Units
import LunaNext.Common 0.1
import LuneOS.Forms 1.0

/*
 * The strip along the foot of a preference page with the green button that
 * closes it, as every webOS preferences scene ended, rather than leaving the
 * way out in the header or to be scrolled to. An AppPage's footer:
 *
 *     AppPage {
 *         signal closed()
 *         footer: DoneBar { onClicked: page.closed() }
 *     }
 */
Rectangle {
    id: doneBar

    property alias text: button.text

    signal clicked()

    implicitHeight: Units.gu(7)
    color: Colors.footerBackground

    HorizontalSeparator {
        anchors.top: parent.top
        width: parent.width
    }

    Button {
        id: button

        anchors.centerIn: parent
        width: Math.min(parent.width - Units.gu(4), Units.gu(32))
        text: "Done"
        LuneOSButton.mainColor: LuneOSButton.affirmativeColor
        onClicked: doneBar.clicked()
    }
}
