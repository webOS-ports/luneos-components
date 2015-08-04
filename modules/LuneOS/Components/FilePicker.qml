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

import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import Qt.labs.folderlistmodel 2.1
import "js/MultiSelect.js" as MultiSelect
import LunaNext.Common 0.1

Rectangle {
    id: filePicker

    property QtObject fileModel
    property alias folder: folders.folder
    property alias acceptColor: accept.color

    color: "#CCCCCC"
    opacity: 1

    width: Units.gu(35)
    height: Units.gu(52)

    smooth: true
    radius: 10
    anchors.centerIn: parent
    border.color: "#919191"
    border.width: Units.gu(0.1)

    Text {
        anchors.top: parent.top
        //anchors.topMargin: Units.gu(1.5)
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Units.gu(1.5)
        height: Units.gu(5)
        text: "Current location: " + folders.folder
        color: "#333333"
        elide: Text.ElideRight
        font.pixelSize: FontUtils.sizeToPixels("16pt")
        font.family: "Prelude"
        width: parent.width - Units.gu(3)
        wrapMode: Text.WordWrap
    }

    Rectangle {
        id: overlay
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Units.gu(3)
        height: parent.height - Units.gu(12)
        radius: 10
        color: "#EEEEEE"
        border.color: "#919191"
        border.width: Units.gu(0.1)

        Rectangle {
            anchors.top: overlay.top
            anchors.topMargin: Units.gu(0.1)
            anchors.bottom: dividerRectangleBottom1.top
            anchors.left: parent.left
            anchors.leftMargin: Units.gu(1.5)
            id: fileLocation
            width: parent.width - Units.gu(3)
            height: Units.gu(5)
            color: "#EEEEEE"
            visible: folders.parentFolder != ""

            Item {
                id: folderItem
                width: Units.gu(3.2)
                height: Units.gu(3.2)
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    source: "images/icon-folder.png"
                    smooth: true
                    width: Units.gu(3.2)
                    height: Units.gu(3.2)
                }
            }

            Text {
                text: ".."
                anchors.left: parent.left
                anchors.leftMargin: Units.gu(3.7)
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                id: upRegion
                anchors.fill: parent
                onClicked: if (folders.parentFolder != "")
                               up()
            }
        }

        Rectangle {
            id: dividerRectangleBottom1
            color: "#BEBEBE"
            width: parent.width
            height: Units.gu(1 / 10)
            anchors.top: fileLocation.bottom
        }

        ListView {
            id: folderListView
            anchors.top: dividerRectangleBottom1.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Units.gu(0.2)
            height: Units.gu(34)
            clip: true

            FolderListModel {
                id: folders
                rootFolder: "/media/internal/"
            }

            Component {
                id: fileDelegate

                Rectangle {
                    function selected() {
                        if (folders.isFolder(index))
                            openFolder(filePath)
                        else {

                            if (fileModel.allowMultipleFiles) {
                                checkbox.checked = !checkbox.checked

                                if (checkbox.checked) {
                                    MultiSelect.addValue(filePath)
                                } else {
                                    MultiSelect.removeValue(filePath)
                                }
                            } else {
                                fileModel.accept(filePath)
                            }
                            //Activate the button (set the color if we have a selection of files)
                            if (MultiSelect.countValues() <= 0) {
                                acceptColor = "#9FC094"
                            } else {
                                acceptColor = "#2aa100"
                            }
                        }
                    }

                    height: Units.gu(5)
                    width: parent.width
                    color: "#EEEEEE"

                    Item {
                        id: filefolderItem
                        width: Units.gu(3.2)
                        height: Units.gu(3.2)
                        anchors.left: parent.left
                        anchors.leftMargin: Units.gu(1.5)
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            source: folders.isFolder(
                                        index) ? "images/icon-folder.png" : "images/icon-file.png"
                            smooth: true
                            width: Units.gu(3.2)
                            height: Units.gu(3.2)
                        }
                    }

                    Text {
                        id: fileNameText
                        anchors.left: parent.left
                        anchors.leftMargin: Units.gu(5.2)
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - filefolderItem.width - checkbox.width - Units.gu(
                                   3)
                        text: fileName
                        elide: Text.ElideRight
                        font.pixelSize: FontUtils.sizeToPixels("14pt")
                        font.family: "Prelude"
                        color: "#444444"
                    }

                    CheckBox {
                        id: checkbox

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        checked: MultiSelect.isSelected(filePath)
                        visible: fileModel.allowMultipleFiles
                                 && !folders.isFolder(index)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selected()
                        }
                    }
                    Rectangle {
                        id: dividerRectangleTop
                        color: "#BEBEBE"
                        width: parent.width
                        height: Units.gu(1 / 10)
                        anchors.top: parent.top
                    }
                    /*Rectangle {
                        id: dividerRectangleBottom
                        color: "#BEBEBE"
                        width: parent.width
                        height: Units.gu(1 / 10)
                        anchors.top: parent.bottom
                    }*/
                }
            }
            model: folders
            delegate: fileDelegate
        }
    }

    Row {
        id: buttonRow
        spacing: Units.gu(0.5)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: overlay.bottom
        anchors.topMargin: Units.gu(3)

        DialogButton {
            id: cancel
            text: "Cancel"
            onClicked: fileModel.reject()
            buttonWidth: Units.gu(15.5)
            color: "white"
            fontcolor: "#444444"
            border.color: "#B8B8B8"
            border.width: Units.gu(0.1)
        }

        DialogButton {
            id: accept
            text: "OK"
            buttonWidth: Units.gu(15.5)
            color: "#9FC094"
            fontcolor: "white"
            onClicked: {
                if (MultiSelect.countValues() <= 0) {
                    console.log("Nothing selected")
                } else {
                    fileModel.accept(MultiSelect.selectedValues())
                }
            }
        }
    }

    function openFolder(path) {
        folders.folder = path
    }

    function up() {
        folders.folder = folders.parentFolder
    }
}
