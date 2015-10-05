/*
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
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

import QtQuick 2.1
import QtQuick.Controls 1.0
import LunaNext.Common 0.1
import QtWebEngine 1.1

WebEngineDialog {
    id: permDialog

    property var requestedFeature;
    property url securityOrigin;
    property WebEngineView view;
    dialogHeight: Units.gu(22)
    dialogWidth: Units.gu(30)
    visible: false
    message: ""

    function textForFeature(feature) {
        if (feature === WebEngineView.MediaAudioCapture)
            return "your microphone"
        if (feature === WebEngineView.MediaVideoCapture)
            return "your camera"
        if (feature === WebEngineView.MediaAudioVideoCapture)
            return "your camera and microphone"
        if (feature === WebEngineView.Geolocation)
            return "your location"
    }

    function titleForFeature(feature) {
        if (feature === WebEngineView.MediaAudioCapture)
            return "Microphone Access"
        if (feature === WebEngineView.MediaVideoCapture)
            return "Camera Access"
        if (feature === WebEngineView.MediaAudioVideoCapture)
            return "Camera and Microphone Access"
        if (feature === WebEngineView.Geolocation)
            return "Location Services"
    }


    onRequestedFeatureChanged: {
        console.log("Herrie onRequestedFeatureChanged")
        permDialog.message = securityOrigin + " wants to access " +textForFeature(requestedFeature);
        permDialog.title = titleForFeature(requestedFeature);
        permDialog.dialogIcon.visible = true
    }

  /*  Row {
        spacing: Units.gu(3.5)
        Text {
            anchors.bottom: okButton.top
            id: message
            color: "red"
            text: "Test"
            z: 5
            //Layout.fillWidth: true

        }
    }*/
    Row
    {
        WebEngineDialogButton {
            id: okButton
            text: "Accept"
            onClicked: {
                permDialog.visible = false;
                view.grantFeaturePermission(securityOrigin, requestedFeature, true);

            }

            color: "green"
            fontcolor: "#FFFFFF"
            buttonWidth: Units.gu(28.0)

        }
    }
    Row {
        WebEngineDialogButton {
            text: "Deny"

            onClicked: {
                permDialog.visible = false
                view.grantFeaturePermission(securityOrigin, requestedFeature, false);

            }
            color: "red"
            fontcolor: "#FFFFFF"
            buttonWidth: Units.gu(28.0)
        }
    }
}
