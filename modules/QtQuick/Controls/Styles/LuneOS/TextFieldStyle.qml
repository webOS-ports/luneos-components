/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
 *               2015 The Qt Company Ltd.
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

import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Controls.Private 1.0
import LunaNext.Common 0.1

Style {
    id: style

    readonly property TextField control: __control

    padding { top: Units.gu(0.5) ; left: Units.gu(1.5) ; right: Units.gu(1.5) ; bottom: Units.gu(0.5) }

    property font font
    property color textColor: "#4b4b4b"
    property color selectionColor: "#69cdff"
    property color selectedTextColor: "white"
    property string passwordCharacter: "\u2022" // Qt.styleHints.passwordMaskCharacter will be available in 5.5
    property int renderType: Settings.isMobile ? Text.QtRendering : Text.NativeRendering

    property color placeholderTextColor: "#7d7d7d"

    property Component background: Rectangle {
        color: "#ffffff"
        opacity: control.enabled ? 1.0 : 0.4
        border.width: Units.gu(0.1)
        border.color: control.activeFocus ? "#69cdff" : "#a2a2a2"
        radius: 16
    }

    property Component panel: Item {
        anchors.fill: parent

        property int topMargin: padding.top
        property int leftMargin: padding.left
        property int rightMargin: padding.right
        property int bottomMargin: padding.bottom

        property color textColor: style.textColor
        property color selectionColor: style.selectionColor
        property color selectedTextColor: style.selectedTextColor

        implicitWidth: backgroundLoader.implicitWidth || Math.round(control.__contentHeight * 8)
        implicitHeight: backgroundLoader.implicitHeight || Math.max(25, Math.round(control.__contentHeight * 2))
        baselineOffset: padding.top + control.__baselineOffset

        property color placeholderTextColor: style.placeholderTextColor
        property font font: style.font

        Loader {
            id: backgroundLoader
            sourceComponent: background
            anchors.fill: parent
        }
    }

    property Component __cursorHandle
    property Component __selectionHandle
    property Component __cursorDelegate
}

