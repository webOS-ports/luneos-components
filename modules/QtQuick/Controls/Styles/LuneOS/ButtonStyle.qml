/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.0
import LunaNext.Common 0.1

ButtonStyle {
    id: buttonStyle

    padding {
        left: Units.gu(1.5)
        right: Units.gu(1.5)
    }

    background: Rectangle {
        color: control.pressed ? "#69cdff" : "transparent"
        Text {
            id: decoratorLeft
            text: "( "
            font.pixelSize: FontUtils.sizeToPixels("large")
            font.weight: Font.Bold
            anchors.left: parent.left
            color: "#4b4b4b"
        }

        Text {
            id: decoratorRight
            text: " )"
            font.pixelSize: FontUtils.sizeToPixels("large")
            font.weight: Font.Bold
            anchors.right: parent.right
            color: "#4b4b4b"
        }
    }

    label: Text {
        text: control.text
        color: !control.enabled ? "#a2a2a2" : "#4b4b4b"
    }
}
