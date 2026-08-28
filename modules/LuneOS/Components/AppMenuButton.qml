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
import QtQuick.Controls 2.5
import QtQuick.Templates 2.5 as T

/**
 * The webOS application menu affordance: a rounded pill in the top-left
 * corner showing the application's name with a chevron, which opens the app
 * menu beneath it.
 *
 * FOR THE DESKTOP TEST HOST ONLY. On a device the status bar draws this
 * affordance itself and opens the menu by relaunching the app with
 * palm-command open-app-menu -- an app answers that relaunch and never draws
 * a button of its own. Only when the app runs standalone (from QtCreator,
 * through its main-desktop.qml) is there no status bar and so no other way
 * into the menu; this button fills that gap and nothing more. Show it only
 * behind the desktop flag, as the phone app does with `runningOnDesktop`.
 *
 * Assign a Menu to `menu` and it is popped up under the pill:
 *
 *     AppMenuButton {
 *         text: "Phone"
 *         visible: runningOnDesktop
 *         menu: Menu { MenuItem { text: "Preferences" } }
 *     }
 */
Item {
    id: appMenuButton

    /// The application's name, as shown in the pill.
    property string text: ""
    /// The menu to open. Popped up left-aligned under the pill.
    /*
     * The menu this opens, as the template rather than as Controls' own Menu.
     * A menu is drawn by whichever style the file declaring it imports, and
     * each style's Menu is a distinct type; naming one of them here would
     * refuse every other. What they all have in common is the template they
     * are built on.
     */
    property T.Menu menu

    property color textColor: "#ffffff"
    property color backgroundColor: "#3a3c3e"
    property color pressedColor: "#4a4c4e"
    property color borderColor: "#1a1a1a"

    signal clicked();

    readonly property bool opened: !!menu && menu.visible

    implicitWidth: label.implicitWidth + chevron.width + Math.round(height * 1.1)
    implicitHeight: 32
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: (mouseArea.pressed || appMenuButton.opened) ? appMenuButton.pressedColor
                                                           : appMenuButton.backgroundColor
        border.color: appMenuButton.borderColor
        border.width: 1
    }

    Text {
        id: label

        anchors {
            left: parent.left
            leftMargin: Math.round(parent.height * 0.45)
            verticalCenter: parent.verticalCenter
        }
        color: appMenuButton.textColor
        font.pixelSize: Math.round(parent.height * 0.45)
        font.bold: true
        text: appMenuButton.text
    }

    // A downward chevron, drawn rather than shipped so it takes the text colour.
    Canvas {
        id: chevron

        anchors {
            left: label.right
            leftMargin: Math.round(parent.height * 0.28)
            verticalCenter: parent.verticalCenter
        }
        width: Math.round(parent.height * 0.3)
        height: Math.round(parent.height * 0.2)

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = appMenuButton.textColor;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(width, 0);
            ctx.lineTo(width / 2, height);
            ctx.closePath();
            ctx.fill();
        }

        Connections {
            target: appMenuButton
            function onTextColorChanged() { chevron.requestPaint(); }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            appMenuButton.clicked();

            if (!appMenuButton.menu)
                return;

            if (appMenuButton.menu.visible)
                appMenuButton.menu.close();
            else
                appMenuButton.menu.popup(appMenuButton, 0, appMenuButton.height);
        }
    }
}
