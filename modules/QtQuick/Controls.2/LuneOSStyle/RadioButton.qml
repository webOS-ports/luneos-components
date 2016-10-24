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
import QtQuick.Controls 2.0
import QtQuick.Controls.impl 2.0
import QtQuick.Templates 2.0 as T
import QtQml.Models 2.2

import LunaNext.Common 0.1

T.RadioButton {
    id: control

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    baselineOffset: contentItem.y + contentItem.baselineOffset

    padding: 6
    spacing: 6
    opacity: enabled ? 1 : 0.2

    property bool useCollapsedLayout: typeof Positioner.index !== 'undefined' && (!!parent.useCollapsedLayout)
    property bool isFirst: useCollapsedLayout && Positioner.isFirstItem
    property bool isLast: useCollapsedLayout && Positioner.isLastItem
    property bool isSingle: isFirst && isLast

    font.family: "Prelude"
    font.pixelSize: FontUtils.sizeToPixels("medium")
    font.weight: Font.Light

    //! [indicator]
    indicator: RadioIndicatorLuneOS {
        x: text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding) : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        control: control
        visible: !useCollapsedLayout
    }
    //! [indicator]

    //! [contentItem]
    contentItem: Text {
        leftPadding: control.indicator && control.indicator.visible && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.indicator.visible && control.mirrored ? control.indicator.width + control.spacing : 0

        text: control.text
        font: control.font
        color: control.down ? "#26282a" : "#353637"
        elide: Text.ElideRight
        visible: control.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    //! [contentItem]

    //! [background]
    background: BorderImage {
        property string _positionButton: isSingle ? "single" :
                                            isFirst ? "first" :
                                               isLast ? "last" : "middle"
        property string _pressed: (control.pressed || control.checked) ? "-pressed" : ""
        source: useCollapsedLayout ? "images/radiobutton-"+_positionButton+_pressed+".png" : ""
        width: control.width; height: control.height
        border.left: 5; border.top: 5
        border.right: 5; border.bottom: 5
        visible: useCollapsedLayout
    }
    //! [background]
}
