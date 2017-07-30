/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.6
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.0

import LuneOS.Components 1.0
import LunaNext.Common 0.1

ApplicationWindow {
    id: window
    width: 360
    height: 520
    visible: true
    title: "Qt Quick Controls 2"

    property string currentDir: Qt.resolvedUrl(".")

    header: ToolBar {
        RowLayout {
            spacing: 20
            anchors.fill: parent

            ToolButton {
                contentItem: Image {
                    fillMode: Image.Pad
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter
                    source: Qt.resolvedUrl("images/drawer.png")
                }
                onClicked: drawer.open()
            }

            Label {
                id: titleLabel
                text: "Gallery"
                color: "white"

                font.family: "Prelude"
                font.pixelSize: FontUtils.sizeToPixels("medium")
                font.weight: Font.Light

                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            ToolButton {
                contentItem: Image {
                    fillMode: Image.Pad
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter
                    source: Qt.resolvedUrl("images/menu.png")
                }
                onClicked: optionsMenu.open()

                Menu {
                    id: optionsMenu
                    x: parent.width - width
                    transformOrigin: Menu.TopRight

                    MenuItem {
                        text: "About"
                        onTriggered: aboutDialog.open()
                    }
                    MenuItem {
                        text: "About"
                        onTriggered: aboutDialog.open()
                    }
                }
            }
        }
    }

    Drawer {
        id: drawer
        width: Math.min(window.width, window.height) / 3 * 2
        height: window.height

        Pane {
            anchors.fill: parent
            padding: 0

            ListView {
                id: listView
                currentIndex: -1
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: handleToolbar.top

                delegate: ItemDelegate {
                    width: parent.width
                    text: model.title
                    highlighted: ListView.isCurrentItem
                    onClicked: {
                        if (listView.currentIndex != index) {
                            listView.currentIndex = index
                            titleLabel.text = model.title
                            stackView.replace(model.source)
                        }
                        drawer.close()
                    }

                    property int ourIndex: index

                    ListDelegateSeparator {
                        anchors.fill: parent
                        index: ourIndex
                        count: listView.model.count
                    }
                }

                model: ListModel {
                    id: subPagesModel
                    Component.onCompleted: {
                        var listPages = [
                     { "title": "BusyIndicator ✓", "source": currentDir + "pages/BusyIndicatorPage.qml" },
                     { "title": "Button ✓", "source": currentDir + "pages/ButtonPage.qml" },
                     { "title": "CheckBox ✓", "source": currentDir + "pages/CheckBoxPage.qml" },
                     { "title": "ComboBox ✓", "source": currentDir + "pages/ComboBoxPage.qml" },
                     { "title": "Dial", "source": currentDir + "pages/DialPage.qml" },
                     { "title": "Delegates ✓", "source": currentDir + "pages/DelegatePage.qml" },
                     { "title": "Drawer ✓", "source": currentDir + "pages/DrawerPage.qml" },
                     { "title": "Frame ✓", "source": currentDir + "pages/FramePage.qml" },
                     { "title": "GroupBox ✓", "source": currentDir + "pages/GroupBoxPage.qml" },
                     { "title": "Menu ✓", "source": currentDir + "pages/MenuPage.qml" },
                     { "title": "PageIndicator", "source": currentDir + "pages/PageIndicatorPage.qml" },
                     { "title": "Popup ✓", "source": currentDir + "pages/PopupPage.qml" },
                     { "title": "ProgressBar ✓", "source": currentDir + "pages/ProgressBarPage.qml" },
                     { "title": "RadioButton ✓", "source": currentDir + "pages/RadioButtonPage.qml" },
                     { "title": "RangeSlider", "source": currentDir + "pages/RangeSliderPage.qml" },
                     { "title": "ScrollBar", "source": currentDir + "pages/ScrollBarPage.qml" },
                     { "title": "ScrollIndicator", "source": currentDir + "pages/ScrollIndicatorPage.qml" },
                     { "title": "Slider ✓", "source": currentDir + "pages/SliderPage.qml" },
                     { "title": "SpinBox", "source": currentDir + "pages/SpinBoxPage.qml" },
                     { "title": "StackView", "source": currentDir + "pages/StackViewPage.qml" },
                     { "title": "SwipeView ✓", "source": currentDir + "pages/SwipeViewPage.qml" },
                     { "title": "Switch ✓", "source": currentDir + "pages/SwitchPage.qml" },
                     { "title": "TabBar ✓", "source": currentDir + "pages/TabBarPage.qml" },
                     { "title": "TextArea ✓", "source": currentDir + "pages/TextAreaPage.qml" },
                     { "title": "TextField ✓", "source": currentDir + "pages/TextFieldPage.qml" },
                     { "title": "ToolTip", "source": currentDir + "pages/ToolTipPage.qml" },
                     { "title": "Tumbler", "source": currentDir + "pages/TumblerPage.qml" }
                                             ];
                        for(var elt in listPages) {
                            subPagesModel.append(listPages[elt]);
                        }
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator { }
            }

            ToolBar {
                id: handleToolbar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                Image {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    fillMode: Image.Pad
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter
                    source: Qt.resolvedUrl("images/drag-handle.png")
                }
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent

        initialItem: Pane {
            id: pane

            Image {
                id: logo
                width: pane.availableWidth / 2
                height: pane.availableHeight / 2
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -50
                fillMode: Image.PreserveAspectFit
                source: Qt.resolvedUrl("images/qt-logo.png")
            }

            Label {
                text: "Qt Quick Controls 2 provides a set of controls that can be used to build complete interfaces in Qt Quick."
                anchors.margins: 20
                anchors.top: logo.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: arrow.top
                horizontalAlignment: Label.AlignHCenter
                verticalAlignment: Label.AlignVCenter
                wrapMode: Label.Wrap
            }

            Image {
                id: arrow
                source: Qt.resolvedUrl("images/arrow.png")
                anchors.left: parent.left
                anchors.bottom: parent.bottom
            }
        }
    }

    Popup {
        id: aboutDialog
        modal: true
        focus: true
        x: (window.width - width) / 2
        y: window.height / 6
        width: Math.min(window.width, window.height) / 3 * 2
        contentHeight: aboutColumn.height

        Column {
            id: aboutColumn
            spacing: 20

            Label {
                text: "About"
                font.bold: true

                font.family: "Prelude"
                font.pixelSize: FontUtils.sizeToPixels("medium")
                font.weight: Font.Light
            }

            Label {
                width: aboutDialog.availableWidth
                text: "The Qt Quick Controls 2 module delivers the next generation user interface controls based on Qt Quick."
                wrapMode: Label.Wrap

                font.family: "Prelude"
                font.pixelSize: FontUtils.sizeToPixels("small")
                font.weight: Font.Light
            }

            Label {
                width: aboutDialog.availableWidth
                text: "In comparison to the desktop-oriented Qt Quick Controls 1, Qt Quick Controls 2 "
                    + "are an order of magnitude simpler, lighter and faster, and are primarily targeted "
                    + "towards embedded and mobile platforms."
                wrapMode: Label.Wrap

                font.family: "Prelude"
                font.pixelSize: FontUtils.sizeToPixels("small")
                font.weight: Font.Light
            }
        }
    }
}
