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

T.TextField {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            placeholder.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    property bool showBg:true

    padding: 6
    leftPadding: padding + 5
    rightPadding: padding + 5
    topPadding: padding + 5
    bottomPadding: padding + 5

    opacity: enabled ? 1 : 0.2
    color: "#353637"
    selectionColor: "#338fff"
    selectedTextColor: "white"
    verticalAlignment: TextInput.AlignVCenter

    font.family: "Prelude"
    font.pixelSize: FontUtils.sizeToPixels("medium")
    font.weight: Font.Light

    Text {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - (control.leftPadding + control.rightPadding)
        height: control.height - (control.topPadding + control.bottomPadding)

        text: control.placeholderText
        font: control.font
        color: "#646464"
        horizontalAlignment: control.horizontalAlignment
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
    }

    //! [background]
    background: Item {
        anchors.fill: control
        BorderImage {
            source: "images/input-focus.png"
            anchors.fill: parent
            border.left: 10; border.top: 10
            border.right: 10; border.bottom: 10
            visible: control.activeFocus
        }
        BorderImage {
            source: "images/input-tool.png"
            anchors.fill: parent
            border.left: 6; border.top: 6
            border.right: 6; border.bottom: 6
            visible: !control.activeFocus && showBg
        }
    }
    //! [background]
}
