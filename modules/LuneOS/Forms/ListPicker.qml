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
import QtQuick.Layouts 1.3

// Theme specific properties
import QtQuick.Controls.LuneOS 2.0
// Units & font sizes
import LunaNext.Common 0.1
import LuneOS.Forms 1.0

/*
 * Pick one entry out of a list, with a search box above it once the list is
 * long enough to be worth searching (it matches label, sublabel and note) -
 * the shape the Mojo apps used for languages, regions, time zones and
 * keyboards alike. ListPickerPopup puts it in a popup; a page can use it as
 * it is (Remote's device pickers).
 *
 * Entries are { key, label, sublabel, note }: "label" is the line you read,
 * "sublabel" the greyed line under it, "note" the value on the right. Only
 * label is required; "title" and "subtitle" are read as label and note, so
 * a list of { title, subtitle } works too. The entry comes back whole in
 * picked(), whatever else it carries.
 *
 * With actionText set, each row gets a button of its own as well (Remote's
 * "Try", which sends a key from that remote without choosing it).
 */
Item {
    id: listPicker

    property var entries: []
    property string currentKey: ""
    // The message shown in place of the list when there is nothing in it
    property string emptyText: "Nothing to choose from"
    property bool loading: false
    property int searchThreshold: 12
    property string actionText: ""

    signal picked(string key, var entry)
    signal actionClicked(var entry)

    readonly property bool searchable: entries.length >= searchThreshold
    readonly property alias searchText: searchField.text

    function clearSearch() {
        searchField.text = "";
    }

    function _label(entry) { return entry.label !== undefined ? entry.label : (entry.title || ""); }
    function _note(entry) { return entry.note !== undefined ? entry.note : (entry.subtitle || ""); }

    readonly property var visibleEntries: {
        var filter = searchField.text.toLowerCase().trim();
        if (filter === "" || !searchable)
            return entries;

        var matches = [];
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i];
            if (_label(entry).toLowerCase().indexOf(filter) >= 0 ||
                (entry.sublabel || "").toLowerCase().indexOf(filter) >= 0 ||
                _note(entry).toLowerCase().indexOf(filter) >= 0)
                matches.push(entry);
        }
        return matches;
    }

    implicitWidth: Units.gu(40)
    implicitHeight: Units.gu(40)

    ColumnLayout {
        anchors.fill: parent
        spacing: Units.gu(1)

        TextField {
            id: searchField
            Layout.fillWidth: true
            Layout.preferredHeight: Units.gu(5)
            visible: listPicker.searchable
            placeholderText: "Search"
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        }

        Label {
            Layout.fillWidth: true
            visible: list.count === 0
            Layout.preferredHeight: visible ? Units.gu(6) : 0
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: listPicker.loading ? "Loading..."
                : listPicker.entries.length === 0 ? listPicker.emptyText : "No match"
            color: Colors.secondaryText
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            model: listPicker.visibleEntries

            delegate: ItemDelegate {
                id: row

                width: ListView.view.width
                height: modelData.sublabel ? Units.gu(8) : Units.gu(6)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Units.gu(1)
                    anchors.rightMargin: Units.gu(1)
                    spacing: Units.gu(1)

                    Column {
                        Layout.fillWidth: true

                        Label {
                            width: parent.width
                            text: listPicker._label(modelData)
                            elide: Text.ElideRight
                            font.bold: modelData.key !== undefined && modelData.key === listPicker.currentKey
                            font.pixelSize: FontUtils.sizeToPixels("medium")
                        }
                        Label {
                            width: parent.width
                            visible: !!modelData.sublabel
                            height: visible ? implicitHeight : 0
                            text: modelData.sublabel ? modelData.sublabel : ""
                            elide: Text.ElideRight
                            color: Colors.secondaryText
                            font.pixelSize: FontUtils.sizeToPixels("small")
                        }
                    }

                    Label {
                        visible: text !== ""
                        text: listPicker._note(modelData)
                        color: Colors.secondaryText
                        font.pixelSize: FontUtils.sizeToPixels("small")
                    }

                    Button {
                        visible: listPicker.actionText !== ""
                        text: listPicker.actionText
                        LuneOSButton.mainColor: LuneOSButton.secondaryColor
                        onClicked: listPicker.actionClicked(modelData)
                    }
                }

                HorizontalSeparator {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    visible: index < list.count - 1
                }

                onClicked: listPicker.picked(modelData.key !== undefined ? modelData.key : "", modelData)
            }

            ScrollIndicator.vertical: ScrollIndicator { }
        }
    }
}
