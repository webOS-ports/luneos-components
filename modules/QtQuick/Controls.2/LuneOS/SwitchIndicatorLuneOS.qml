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

import LunaNext.Common 0.1

Item {
    implicitWidth: indicatorOn.implicitWidth + Math.max(Math.max(onLabelText.implicitWidth,offLabelText.implicitWidth) - 20, 0)
    implicitHeight: indicatorOn.implicitHeight

    property Item control
    property string onLabel: ""
    property string offLabel: ""
    opacity: control.enabled ? 1 : 0.3

    BorderImage {
        id: indicatorOn
        source: "images/toggle-button-on.png"
        anchors.fill: parent
        border.left: 7; border.top: 7
        border.right: 30; border.bottom: 7
        opacity: control.checked ? 1 : 0

        Text {
            id: onLabelText
            text: onLabel
            font.capitalization: Font.AllUppercase

            color: "white"
            font.family: "Prelude"
            font.pixelSize: FontUtils.sizeToPixels("small")
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            anchors.fill: parent
            anchors.topMargin: 2
            anchors.leftMargin: 7
            anchors.rightMargin: 32
        }
    }
    BorderImage {
        id: indicatorOff
        source: "images/toggle-button-off.png"
        anchors.fill: parent
        border.left: 30; border.top: 7
        border.right: 7; border.bottom: 7
        opacity: control.checked ? 0 : 1

        Text {
            id: offLabelText
            text: offLabel
            font.capitalization: Font.AllUppercase

            color: "white"
            font.family: "Prelude"
            font.pixelSize: FontUtils.sizeToPixels("small")
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            anchors.fill: parent
            anchors.topMargin: 2
            anchors.leftMargin: 32
            anchors.rightMargin: 7
        }
    }

}
