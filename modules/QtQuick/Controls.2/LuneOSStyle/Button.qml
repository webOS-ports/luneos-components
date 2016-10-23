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

T.Button {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentItem.implicitHeight + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    padding: 6
    leftPadding: padding + 2
    rightPadding: padding + 2

    font.family: "Prelude"
    font.pixelSize: FontUtils.sizeToPixels("medium")
    font.weight: Font.Light

    property QtObject colors: QtObject {
        property color primary: "#80171717"
        property color secondary: "#CCFFFFFF"
        property color affirmative: "#2aa100"
        property color negative: "#be0003"
        property color blue: "#2071bb"
        property color gray: "#4b4b4b"
    }

    property color mainColor: "#292929"
    property color textColor: _isMainColorDark ? "white" : "#292929"
    property bool _isMainColorDark: (mainColor.r*0.299 + mainColor.g*0.587 + mainColor.b*0.114) < 0.726

    //! [contentItem]
    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled || control.highlighted || control.checked ? 1 : 0.4
        color: control.textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    //! [contentItem]

    //! [background]
    background:
        Rectangle {
            implicitWidth: 120
            implicitHeight: 40
            radius: 4
            opacity: enabled ? 1 : 0.4
            visible: !control.flat || control.down || control.checked || control.highlighted
            color: control.mainColor

            BorderImage {
                source: control.down ? "images/button-down.png" : "images/button-up.png"
                border.left: 19; border.right: 19

                anchors.fill: parent
            }
        }
    //! [background]
}
