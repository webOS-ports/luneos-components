/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
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

FakeWindowBase {
    id: dummyWindow

    appId: "org.webosports.tests.dummyWindow"
    type: "_WEBOS_WINDOW_TYPE_CARD"

    property bool isFullScreenModeActive: false;

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "grey" }
            GradientStop { position: 1.0; color: "blue" }
        }
    }

    Flickable {
        id: windowFlickable
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick

        contentHeight: contentColumn.height
        clip: true

        Column {
            id: contentColumn

            anchors.centerIn: parent
            width: parent.width
            spacing: 20

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Test Window App (" + appId + ")"
                font.pointSize: 16
                color: "white"
            }

            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width / 2
                height: 50

                caption: "Fullscreen mode: " + isFullScreenModeActive

                onAction: {
                    isFullScreenModeActive = !isFullScreenModeActive;

                    lunaNextLS2Service.call("luna://org.webosports.luna/enableFullScreenMode",
                                            JSON.stringify({"enable": isFullScreenModeActive}),
                                            undefined, undefined)
                }
            }
            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                caption: "Add notification"
                width: parent.width / 2
                height: 50

                onAction: {
                    lunaNextLS2Service.call("luna://com.webos.notification/createToast",
                                            JSON.stringify({"title": "Test title", "message": "Test notification",
                                                            "iconUrl": Qt.resolvedUrl("default-app-icon.png"),
                                                            "schedule": {"expire": Date.now()/1000+15}}),
                                            undefined, undefined)
                }
            }
            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                caption: "Add banner"
                width: parent.width / 2
                height: 50

                onAction: {
                    lunaNextLS2Service.call("luna://com.webos.notification/createToast",
                                            JSON.stringify({"title": "Test banner", "message": "Test banner",
                                                            "iconUrl": Qt.resolvedUrl("default-app-icon.png"),
                                                            "type": "light"}),
                                            undefined, undefined)
                }
            }
            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                caption: "Focus a dummyWindow2 app"
                width: parent.width / 2
                height: 50

                onAction: {
                    lunaNextLS2Service.call("luna://org.webosports.luna/focusApplication",
                                            JSON.stringify({"appId": "org.webosports.tests.dummyWindow2"}),
                                            undefined, undefined)
                }
            }
            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                caption: "Show power menu"
                width: parent.width / 2
                height: 50

                onAction: {
                    lunaNextLS2Service.call("palm://org.webosports.luna/com/palm/display/powerKeyPressed",
                                            JSON.stringify({"showDialog": true}),
                                            undefined, undefined)
                }
            }
            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                caption: "Create another window"
                width: parent.width / 2
                height: 50

                onAction: {
                    lunaNextLS2Service.call("luna://com.palm.applicationManager/launch",
                        JSON.stringify({"id": "org.webosports.tests.dummyWindow", "params": {}}), undefined, undefined)
                }
            }
            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                caption: "Create popup overlay window"
                width: parent.width / 2
                height: 50

                onAction: {
                    lunaNextLS2Service.call("luna://com.palm.applicationManager/launch",
                        JSON.stringify({"id": "org.webosports.tests.fakePopupAlertWindow", "params": {}}), undefined, undefined)
                }
            }
            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                negative: true
                caption: "Kill me"
                width: parent.width / 2
                height: 50

                onAction: {
                    // commit suicide
                    dummyWindow.destroy();
                }
            }

            TextInput {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "try me !"
            }
        }
    }
}
