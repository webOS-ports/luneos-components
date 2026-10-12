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
import QtQuick.Layouts 1.3

// Units & font sizes
import LunaNext.Common 0.1
import LuneOS.Forms 1.0

/*
 * A ListPicker in a popup, with a title over it and Cancel under it. Picking
 * an entry closes it. The API is Settings' ListPickerPopup's, which this
 * replaces:
 *
 *     ListPickerPopup {
 *         id: languagePicker
 *         title: "Language"
 *         entries: [{ "key": "nl", "label": "Nederlands", "sublabel": "Dutch" }]
 *         onPicked: (key, entry) => chooseLanguage(key)
 *     }
 */
Popup {
    id: popup

    property string title: ""
    property alias entries: picker.entries
    property alias currentKey: picker.currentKey
    property alias emptyText: picker.emptyText
    property alias loading: picker.loading
    property alias searchThreshold: picker.searchThreshold

    signal picked(string key, var entry)

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: Math.min(parent.width - Units.gu(4), Units.gu(46))
    height: Math.min(parent.height - Units.gu(4), Units.gu(70))

    onOpened: picker.clearSearch()

    ColumnLayout {
        anchors.fill: parent
        spacing: Units.gu(1)

        Label {
            Layout.fillWidth: true
            visible: popup.title !== ""
            text: popup.title
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: FontUtils.sizeToPixels("18pt")
            font.weight: Font.Bold
        }

        ListPicker {
            id: picker
            Layout.fillWidth: true
            Layout.fillHeight: true

            onPicked: (key, entry) => {
                popup.picked(key, entry);
                popup.close();
            }
        }

        Button {
            Layout.fillWidth: true
            text: "Cancel"
            onClicked: popup.close()
        }
    }
}
