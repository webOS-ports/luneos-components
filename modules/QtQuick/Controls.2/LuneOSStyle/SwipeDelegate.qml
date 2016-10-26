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
import QtQuick.Templates 2.0 as T

import LunaNext.Common 0.1

T.SwipeDelegate {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             Math.max(contentItem.implicitHeight,
                                      indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    padding: 12
    spacing: 12

    font.family: "Prelude"
    font.pixelSize: FontUtils.sizeToPixels("medium")
    font.weight: Font.Light

    property string confirmText: "Confirm"
    signal confirmed()
    onClicked: {
        if(swipe.complete) control.confirmed();
    }

    // Tofe remark: currently the SwipeDelegate C++ template filters out all mouse events from left,right and behind
    //              items. In addition, there is no API to reset the swiped delegate to its original position.
    //              Therefore we simply draw a big red button, and send a "confirmed" signal if we see a
    //              click on it and the item is fully swiped out.
    //      In Qt 5.8, there will be a swipe.close() function and the interactive items in left,right and behind will
    //      be functional (through SwipeDelegate.onClicked for instance)
    swipe.behind: Rectangle {
        width: control.width; height: control.height
        radius: 4
        color: "#be0003"
        opacity: control.swipe.complete ? 1.0 : 0.3

        BorderImage {
            source: (control.down && control.swipe.complete) ? "images/button-down.png" : "images/button-up.png"
            border.left: 19; border.right: 19
            anchors.fill: parent
        }
        Text {
            anchors.centerIn: parent
            text: control.confirmText
            font: control.font
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    //! [contentItem]
    contentItem: Text {
        leftPadding: control.mirrored ? (control.indicator ? control.indicator.width : 0) + control.spacing : 0
        rightPadding: !control.mirrored ? (control.indicator ? control.indicator.width : 0) + control.spacing : 0

        text: control.text
        font: control.font
        color: control.enabled ? "#26282a" : "#bdbebf"
        elide: Text.ElideRight
        visible: control.text
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter

        Behavior on x {
            enabled: !control.down
            NumberAnimation {
                easing.type: Easing.OutExpo
                duration: 400
            }
        }
    }
    //! [contentItem]

    //! [background]
    background: Rectangle {
        color: control.visualFocus ? (control.down ? "#cce0ff" : "#e5efff") : (control.down ? "#bdbebf" : "#ffffff")

        Behavior on x {
            enabled: !control.down
            NumberAnimation {
                easing.type: Easing.OutExpo
                duration: 400
            }
        }
    }
    //! [background]
}
