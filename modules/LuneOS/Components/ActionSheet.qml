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
import QtQuick.Controls

import LunaNext.Common 0.1

/*
 * A short list of choices over the page - the Enyo guidelines' "action
 * dialog": what to do with a song or a file, which track or speed, how
 * long a timer runs. On a phone it rises from the bottom; on a wider
 * window it sits in the middle. A tap outside closes it, as does back()
 * (call it from the app's back gesture handling).
 *
 * Drawn inside the window rather than as a popup layer, so it turns with
 * a page that is turned (Videos' player).
 *
 *     ActionSheet { id: sheet; anchors.fill: parent }
 *
 *     sheet.show("Song title", [
 *         { label: "Play Next", action: function() { ... } },
 *         { label: "Speed", header: true },
 *         { label: "1.5×", key: 1.5, checked: true },
 *         { label: "Delete", destructive: true, action: ... },
 *     ], "Artist")
 *
 * A choice runs its action(), if it has one, and chosen(choice) is emitted
 * either way. Its fields: label, key, checked (a tick), header (a heading
 * row, not a choice), destructive (red), enabled (false greys it out).
 */
Item {
    id: sheet

    property string title
    property string subtitle
    property var choices: []
    // "auto" rises from the bottom on a narrow window and is centred on a
    // wide one; "bottom" and "center" force one.
    property string placement: "auto"
    readonly property bool shown: _shown

    signal chosen(var choice)

    property bool _shown: false

    readonly property real headerRowHeight: Units.gu(4.5)
    readonly property real rowHeight: Math.max(Units.gu(6), 54)
    readonly property bool centered: placement === "center" || (placement === "auto" && width > Units.gu(70))
    readonly property real listHeight: {
        var h = 0;
        for (var i = 0; i < choices.length; i++)
            h += choices[i].header ? headerRowHeight : rowHeight;
        return h;
    }

    visible: _shown || slide.running
    z: 1000

    function show(newTitle, newChoices, newSubtitle) {
        title = newTitle || "";
        choices = newChoices || [];
        subtitle = newSubtitle || "";
        list.positionViewAtBeginning();
        _shown = true;
    }

    function hide() {
        _shown = false;
    }

    /* For the back gesture: closes the sheet if it is open, and says so. */
    function back() {
        if (!_shown)
            return false;
        hide();
        return true;
    }

    function choose(index) {
        var choice = choices[index];
        if (!choice || choice.header || choice.enabled === false)
            return;
        hide();
        if (typeof choice.action === "function")
            choice.action();
        chosen(choice);
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: sheet._shown ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    // A tap outside closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: sheet.hide()
    }

    Rectangle {
        id: panel
        objectName: "sheetPanel"
        width: sheet.centered ? Math.min(sheet.width - Units.gu(4), Units.gu(48)) : sheet.width
        height: Math.min(sheet.height - (sheet.centered ? Units.gu(4) : Units.gu(6)),
                         heading.height + sheet.listHeight + Units.gu(1.5))
        anchors.horizontalCenter: parent.horizontalCenter
        y: sheet.centered ? (sheet._shown ? (sheet.height - height) / 2 : sheet.height)
                          : (sheet._shown ? sheet.height - height : sheet.height)
        radius: Units.gu(1)
        color: "#f2202020"
        border.color: "#555555"
        Behavior on y { NumberAnimation { id: slide; duration: 180; easing.type: Easing.OutCubic } }

        // Taps on the panel stay on it.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: heading
            x: Units.gu(2)
            width: parent.width - Units.gu(4)
            height: sheet.title === "" ? Units.gu(1) : implicitHeight + Units.gu(2)
            topPadding: sheet.title === "" ? 0 : Units.gu(1.5)
            visible: sheet.title !== ""

            Label {
                objectName: "sheetTitle"
                width: parent.width
                text: sheet.title
                color: "white"
                font.pixelSize: FontUtils.sizeToPixels("medium")
                font.bold: true
                elide: Text.ElideRight
            }
            Label {
                objectName: "sheetSubtitle"
                width: parent.width
                visible: text !== ""
                text: sheet.subtitle
                color: "#aaaaaa"
                font.pixelSize: FontUtils.sizeToPixels("small")
                elide: Text.ElideRight
            }
        }

        ListView {
            id: list
            objectName: "sheetList"
            anchors.top: heading.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Units.gu(1)
            clip: true
            model: sheet.choices
            boundsBehavior: Flickable.StopAtBounds

            delegate: ItemDelegate {
                id: choice
                required property var modelData
                required property int index
                objectName: "choice_" + index
                width: list.width
                height: modelData.header ? sheet.headerRowHeight : sheet.rowHeight
                enabled: !modelData.header && modelData.enabled !== false
                padding: 0
                background: Rectangle {
                    color: choice.pressed ? "#44ffffff" : "transparent"
                }
                contentItem: Item {
                    Label {
                        objectName: "choiceLabel"
                        x: Units.gu(2)
                        width: parent.width - Units.gu(8)
                        anchors.verticalCenter: parent.verticalCenter
                        text: choice.modelData.label !== undefined ? choice.modelData.label : (choice.modelData.text || "")
                        elide: Text.ElideRight
                        opacity: choice.modelData.enabled === false ? 0.4 : 1
                        color: choice.modelData.header ? "#999999"
                             : choice.modelData.destructive ? "#ff6b5e" : "white"
                        font.pixelSize: FontUtils.sizeToPixels(choice.modelData.header ? "small" : "medium")
                        font.bold: choice.modelData.header === true
                    }
                    // The tick, drawn: the devices' Prelude font has no U+2713.
                    Item {
                        objectName: "choiceTick"
                        anchors.right: parent.right
                        anchors.rightMargin: Units.gu(2)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Units.gu(2.4)
                        height: width
                        visible: choice.modelData.checked === true

                        Rectangle {
                            x: parent.width * 0.08
                            y: parent.height * 0.52
                            width: parent.width * 0.38
                            height: Math.max(2, parent.width * 0.14)
                            radius: height / 2
                            rotation: 45
                            transformOrigin: Item.Left
                            color: "#7fb9ff"
                        }
                        Rectangle {
                            x: parent.width * 0.32
                            y: parent.height * 0.78
                            width: parent.width * 0.72
                            height: Math.max(2, parent.width * 0.14)
                            radius: height / 2
                            rotation: -50
                            transformOrigin: Item.Left
                            color: "#7fb9ff"
                        }
                    }
                }
                onClicked: sheet.choose(index)
            }
        }
    }
}
