/*
 * Copyright (C) 2026 WebOS Ports
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import LunaNext.Common 0.1

/**
 * A tick box and its label, for the light body of a Dialog.
 *
 * The Controls checkbox is styled for the dark chrome and vanishes against a
 * dialog. This uses the artwork the rest of Dialog is built from, and the
 * whole row is the target rather than only the box.
 */
Item {
    id: dialogCheckBox

    property bool checked: false
    property alias text: label.text
    /// Set by the caller when the label has to wrap inside a known width.
    property real labelWidth: label.implicitWidth

    implicitWidth: box.width + row.spacing + label.width
    implicitHeight: Math.max(box.height, label.implicitHeight)

    width: implicitWidth
    height: implicitHeight

    Row {
        id: row

        anchors.fill: parent
        spacing: Units.gu(1)

        Image {
            id: box

            anchors.verticalCenter: parent.verticalCenter

            width: Units.gu(2.4)
            height: Units.gu(2.4)
            fillMode: Image.PreserveAspectFit
            smooth: true

            source: dialogCheckBox.checked ? "images/checkbox-checked.png"
                                           : "images/checkbox-unchecked.png"
        }

        Text {
            id: label

            anchors.verticalCenter: parent.verticalCenter

            width: dialogCheckBox.labelWidth
            wrapMode: Text.Wrap
            color: "#292929"
            font.family: "Prelude"
            font.pixelSize: FontUtils.sizeToPixels("12pt")
        }
    }

    // A sibling of the row, not a child: a MouseArea filling a Row would be
    // laid out as one of its columns.
    MouseArea {
        anchors.fill: parent
        onClicked: dialogCheckBox.checked = !dialogCheckBox.checked
    }
}
