/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the Qt Quick Controls 2 module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL3$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see http://www.qt.io/terms-conditions. For further
** information use the contact form at http://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPLv3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or later as published by the Free
** Software Foundation and appearing in the file LICENSE.GPL included in
** the packaging of this file. Please review the following information to
** ensure the GNU General Public License version 2.0 requirements will be
** met: http://www.gnu.org/licenses/gpl-2.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Controls 2.0
import QtQuick.Templates 2.0 as T

import LunaNext.Common 0.1
import LuneOS.Components 1.0

T.ComboBox {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             Math.max(contentItem.implicitHeight,
                                      indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    spacing: 8
    padding: 6
    leftPadding: padding + 6
    rightPadding: padding + 6

    opacity: enabled ? 1 : 0.3

    font.family: "Prelude"
    font.pixelSize: FontUtils.sizeToPixels("medium")
    font.weight: Font.Normal

    //! [delegate]
    delegate: ItemDelegate {
        width: control.width
        text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
        font.weight: control.currentIndex === index ? Font.DemiBold : Font.Normal
        checked: control.currentIndex == index

        property int myIndex: index

        ListDelegateSeparator {
            anchors.fill: parent
            index: parent.myIndex
            count: control.count
        }
    }
    //! [delegate]

    //! [indicator]
    indicator: Image {
        x: control.mirrored ? control.leftPadding : control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        source: "images/menu-arrow.png"
        width: 15
        height: 10
    }
    //! [indicator]

    //! [contentItem]
    contentItem: Text {
        leftPadding: control.mirrored && control.indicator ? control.indicator.width + control.spacing : 0
        rightPadding: !control.mirrored && control.indicator ? control.indicator.width + control.spacing : 0

        text: control.displayText
        font: control.font
        color: "#333333"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    //! [contentItem]

    //! [background]
    background: Item { }
    //! [background]

    //! [popup]
    popup: T.Popup {
        y: control.height - (control.visualFocus ? 0 : 1)
        width: control.width
        implicitHeight: Math.min(listview.contentHeight,
                                 Math.max(T.ApplicationWindow.overlay ? T.ApplicationWindow.overlay.height/2 : 0,
                                          control.parent.height))
        topMargin: 6
        bottomMargin: 6

        contentItem: ListView {
                id: listview
                model: control.popup.visible ? control.delegateModel : null
                currentIndex: control.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
                anchors.fill: parent
                clip: true

                T.ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: BorderImage {
            source: "images/popupselect-background.png"
            x: -9; y: -13
            width: parent.width + 9 + 9
            height: parent.height + 13 + 13
            border.left: 15; border.top: 19
            border.right: 15; border.bottom: 19
        }
    }
    //! [popup]
}
