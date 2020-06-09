/*
 * Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; see the file COPYING.  If not, see
 * <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.0
import LunaNext.Common 0.1

Dialog {
    id: certDialog

    message: "Do you want to accept the security \ncertificate?"
    dialogHeight: Units.gu(25)
    dialogWidth: Units.gu(30)

    signal viewCertificate();
    signal trust(bool always);
    signal reject();

    Item
    {
        anchors.top: parent.top
        anchors.topMargin: Units.gu(4.2)
        anchors.horizontalCenter: parent.horizontalCenter
        z:100
        id: notImplemented
        visible: false
            AlertDialog
            {
                dialogHeight: Units.gu(25)
                dialogWidth: Units.gu(30)
                message: "Not yet implemented"
            }

        Connections {
            target: certDialog
            function onViewCertificate() {
                notImplemented.visible = true;
            }
        }
    }

    Row {
        spacing: Units.gu(0.5)
        DialogButton {
            text: "View Certificate"
            color: "#6E6E6E"
            fontcolor: "white"
            buttonWidth: Units.gu(26)

            onClicked: certDialog.viewCertificate();
        }
    }
    Row
    {
        spacing: Units.gu(0.5)
        DialogButton {
            text: "Trust Always"
            color: "#6E6E6E"
            fontcolor: "white"
            buttonWidth: Units.gu(26)

            onClicked: certDialog.trust(true);
        }
    }
    Row
    {
        spacing: Units.gu(0.5)
        DialogButton {
            text: "Trust Once"
            color: "#6E6E6E"
            fontcolor: "white"
            buttonWidth: Units.gu(26)

            onClicked: certDialog.trust(false);
        }
    }
    Row
    {
        spacing: Units.gu(0.5)
        DialogButton {
            text: "Don't Trust"
            color: "#6E6E6E"
            fontcolor: "white"
            buttonWidth: Units.gu(26)

            onClicked: certDialog.reject();
        }
    }
}
