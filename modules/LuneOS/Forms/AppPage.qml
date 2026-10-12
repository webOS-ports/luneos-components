/*
 * (c) 2013 Simon Busch <morphis@gravedo.de>
 * (c) 2017 Christophe Chapuis <chris.chapuis@gmail.com>
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
import QtQuick.Window 2.2

// Units
import LunaNext.Common 0.1
import LuneOS.Forms 1.0

/*
 * A page of a settings-style app: the grey gradient behind the content, an
 * action for the header's right-hand side, and the italic explanation line
 * the legacy apps put under a page ("touch and hold for more"). Settings'
 * BasePage, which Messwerk and Remote had each copied.
 *
 * Not called BasePage: the apps' own BasePage.qml files would then be
 * shadowed by this one wherever LuneOS.Forms is imported.
 */
Page {
    id: appPage

    // Shown on the right of the header (AppWindow puts it there)
    property Component headerAction: null
    property alias explanation: footerText.text
    // On a short screen - the Q25's square - the explanation can give its
    // room to the content. True keeps it everywhere.
    property bool explanationOnShortScreen: true

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: Colors.pageGradientTop }
            GradientStop { position: 1.0; color: Colors.pageGradientBottom }
        }
    }

    footer: ExplanationText {
        id: footerText

        visible: text !== "" && (appPage.explanationOnShortScreen || appPage.Window.height >= Units.gu(60))
        leftPadding: Units.gu(1)
        rightPadding: Units.gu(1)
        bottomPadding: Units.gu(1)
        font.italic: true
    }
}
