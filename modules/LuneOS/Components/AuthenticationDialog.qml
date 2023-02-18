
/*
* Copyright (C) 2014 Morgan McMillian <gilag@monkeystew.com>
* Copyright (C) 2014 Herman van Hazendonk <github.com@herrie.org>
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
import QtQuick.Window 2.1
import QtQuick.Controls 2.0

import LunaNext.Common 0.1

Item {
    id: authDialog

    property string serverURL
    property string hostname
    property string title: "The server " + serverURL + " requires a username and password"
    property string message: hostname + " requires authentication."
    property bool saveHistoryImageChecked: false
    anchors.fill: parent

    signal accepted(string username, string pass, bool savePwd);

    Rectangle {
        id: dimBackground
        anchors.fill: parent
        color: "#4C4C4C"
        opacity: 0.9
    }

    Rectangle {
        id: dialogWindow
        width: Units.gu(40)
        height: confirmRect.y + confirmRect.height + 2*dialogHeader.anchors.margins
        color: "transparent"
        radius: 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenterOffset: -Qt.inputMethod.keyboardRectangle.height/2

        Image {
            id: leftImageTop
            anchors.top: parent.top
            anchors.left: parent.left
            source: "images/dialog-left-top.png"
            height: Units.gu(2.5)
            width: Units.gu(2.5)
        }
        Image {
            id: leftImageMiddle
            height: parent.height - leftImageTop.height - leftImageBottom.height
            anchors.top: leftImageTop.bottom
            anchors.left: parent.left
            source: "images/dialog-left-middle.png"
            fillMode: Image.Stretch
            width: Units.gu(2.5)
        }
        Image {
            id: leftImageBottom
            height: Units.gu(2.5)
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            source: "images/dialog-left-bottom.png"

            width: Units.gu(2.5)
        }

        Image {
            id: centerImageTop
            height: Units.gu(2.5)
            anchors.left: leftImageTop.right
            anchors.top: parent.top
            source: "images/dialog-center-top.png"
            width: parent.width - leftImageTop.width - rightImageTop.width
        }
        Image {
            id: centerImageMiddle
            height: parent.height - centerImageTop.height - centerImageBottom.height
            anchors.left: leftImageMiddle.right
            anchors.top: centerImageTop.bottom
            source: "images/dialog-center-middle.png"
            width: parent.width - leftImageTop.width - rightImageTop.width
            fillMode: Image.Stretch
        }
        Image {
            id: centerImageBottom
            height: Units.gu(2.5)
            anchors.left: leftImageBottom.right
            anchors.bottom: parent.bottom
            source: "images/dialog-center-bottom.png"
            width: parent.width - leftImageBottom.width - rightImageBottom.width
        }

        Image {
            id: rightImageTop
            anchors.right: parent.right
            anchors.top: parent.top
            source: "images/dialog-right-top.png"
            width: Units.gu(2.5)
            height: Units.gu(2.5)
        }
        Image {
            id: rightImageMiddle
            anchors.right: parent.right
            anchors.top: rightImageTop.bottom
            source: "images/dialog-right-middle.png"
            width: Units.gu(2.5)
            height: parent.height - rightImageTop.height - rightImageBottom.height
            fillMode: Image.Stretch
        }

        Image {
            id: rightImageBottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            source: "images/dialog-right-bottom.png"
            width: Units.gu(2.5)
            height: Units.gu(2.5)
        }

        Item {
            id: dialogHeader
            anchors.centerIn: parent
            anchors.fill: parent
            anchors.margins: Units.gu(3)

            Text {
                id: messageText
                width: parent.width
                text: authDialog.title //? authDialog.title : "The server " + webViewItem.url + " requires a username and password"
                horizontalAlignment: Text.AlignLeft
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.Wrap
                font.family: "Prelude"
                font.pixelSize: FontUtils.sizeToPixels("15pt")
                color: Qt.darker("white", 5.)
            }

            Item {
                id: usernameItem
                width: parent.width
                height: username.height * 1.7
                anchors.left: parent.left
                anchors.top: messageText.bottom
                anchors.topMargin: Units.gu(0.2)

                Item {
                    id: usernameBG
                    visible: username.activeFocus
                    anchors.fill: parent

                    Image {
                        id: usernameBGImageLeft
                        source: "images/input-default-focus-left.png"
                        anchors.left: parent.left
                        height: parent.height
                        width: height*12./36.
                    }
                    Image {
                        id: usernameBGImageCenter
                        source: "images/input-default-focus-center.png"
                        anchors.left: usernameBGImageLeft.right
                        anchors.right: usernameBGImageRight.left
                        height: parent.height
                    }
                    Image {
                        id: usernameBGImageRight
                        source: "images/input-default-focus-right.png"
                        anchors.right: parent.right
                        height: parent.height
                        width: height*12./36.
                    }
                }

                Text {
                    id: usernameHint
                    width: parent.width
                    height: username.height
                    text: "Username..."
                    anchors.fill: username
                    font.family: "Prelude"
                    font.pixelSize: FontUtils.sizeToPixels("17pt")
                    color: "#888"
                    visible: (username.length===0)&&(!username.activeFocus)
                }

                TextInput {
                    id: username
                    width: parent.width
                    height: Units.gu(3)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Units.gu(1)
                    clip: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    focus: true
                    font.family: "Prelude"
                    font.pixelSize: FontUtils.sizeToPixels("17pt")
                    color: "black"
                }
            }

            Item {
                id: passwordItem
                width: parent.width
                height: usernameItem.height
                anchors.top: usernameItem.bottom
                anchors.left: parent.left

                Item {
                    id: passwordBG
                    anchors.fill: parent
                    visible: password.activeFocus

                    Image {
                        id: passwordBGImageLeft
                        source: "images/input-default-focus-left.png"
                        anchors.left: parent.left
                        height: parent.height
                        width: height*12./36.
                    }
                    Image {
                        id: passwordBGImageCenter
                        source: "images/input-default-focus-center.png"
                        anchors.left: passwordBGImageLeft.right
                        anchors.right: passwordBGImageRight.left
                        height: parent.height
                    }
                    Image {
                        id: passwordBGImageRight
                        source: "images/input-default-focus-right.png"
                        anchors.right: parent.right
                        height: parent.height
                        width: height*12./36.
                    }
                }

                Text {
                    id: passwordHint
                    width: parent.width
                    text: "Password..."
                    anchors.fill: password
                    font.family: "Prelude"
                    font.pixelSize: FontUtils.sizeToPixels("17pt")
                    color: "#888"
                    visible: (password.length===0)&&(!password.activeFocus)
                }

                TextInput {
                    id: password
                    width: parent.width
                    height: username.height
                    anchors.left: parent.left
                    anchors.leftMargin: Units.gu(1)
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Prelude"
                    font.pixelSize: FontUtils.sizeToPixels("17pt")
                    color: "black"
                }
            }

            Image {
                id: savePWCheckbox
                source: authDialog.saveHistoryImageChecked ? "images/checkbox-checked.png" : "images/checkbox-unchecked.png"
                anchors.left: parent.left
                anchors.top: passwordItem.bottom
                anchors.topMargin: Units.gu(1)
                height: Units.gu(2.4)
                width: Units.gu(2.4)

                MouseArea {
                    anchors.fill: parent
                    onClicked: authDialog.saveHistoryImageChecked = !authDialog.saveHistoryImageChecked;
                }
            }

            Text {
                anchors.left: savePWCheckbox.right
                anchors.leftMargin: Units.gu(1)
                anchors.top: passwordItem.bottom
                anchors.topMargin: Units.gu(1)
                text: "Save password in password manager"
                font.family: "Prelude"
                font.pixelSize: FontUtils.sizeToPixels("medium")
                color: messageText.color
            }

            Rectangle {
                id: cancelRect
                height: Units.gu(4.5)
                anchors.top: savePWCheckbox.bottom
                anchors.topMargin: Units.gu(1)
                anchors.left: parent.left
                width: (parent.width - Units.gu(1)) / 2
                color: "transparent"
                radius: 4
                Image {
                    id: cancelImageLeft
                    source: "images/button-up-left.png"
                    width: Units.gu(1.9)
                    height: parent.height
                    fillMode: Image.Stretch
                    anchors.left: parent.left
                }
                Image {
                    id: cancelImageCenter
                    source: "images/button-up-center.png"
                    width: cancelRect.width - cancelImageLeft.width - cancelImageRight.width
                    height: parent.height
                    fillMode: Image.Stretch
                    anchors.left: cancelImageLeft.right
                }

                Image {
                    id: cancelImageRight
                    source: "images/button-up-right.png"
                    width: Units.gu(1.9)
                    height: parent.height
                    fillMode: Image.Stretch
                    anchors.right: cancelRect.right
                }

                Text {
                    font.family: "Prelude"
                    text: "Cancel"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: {
                        model.reject()
                    }
                }
            }

            Rectangle {
                id: confirmRect
                height: Units.gu(4.5)
                anchors.top: savePWCheckbox.bottom
                anchors.topMargin: Units.gu(1)
                anchors.right: parent.right
                width: (parent.width - Units.gu(1)) / 2
                radius: 4
                color: "#4b4b4b"
                Image {
                    id: confirmImageLeft
                    source: "images/button-up-left.png"
                    width: Units.gu(1.9)
                    height: parent.height
                    fillMode: Image.Stretch
                    anchors.left: parent.left
                }
                Image {
                    id: confirmImageCenter
                    source: "images/button-up-center.png"
                    width: confirmRect.width - confirmImageLeft.width - confirmImageRight.width
                    height: parent.height
                    fillMode: Image.Stretch
                    anchors.left: confirmImageLeft.right
                }

                Image {
                    id: confirmImageRight
                    source: "images/button-up-right.png"
                    height: parent.height
                    fillMode: Image.Stretch
                    anchors.right: confirmRect.right
                }

                Text {
                    font.family: "Prelude"
                    text: "OK"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: authDialog.accepted(username.text, password.text, saveHistoryImageChecked);
                }
            }
        }
    }
}
