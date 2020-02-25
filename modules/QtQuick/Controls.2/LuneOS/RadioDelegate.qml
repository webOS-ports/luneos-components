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

import QtQuick 2.12
import QtQuick.Controls 2.4
import QtQuick.Controls.impl 2.4
import QtQuick.Templates 2.4 as T

import QtQuick.Controls.LuneOS 2.0
import LunaNext.Common 0.1

T.RadioDelegate {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             Math.max(contentItem.implicitHeight,
                                      indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    padding: 12
    spacing: 12

    readonly property int _index: typeof index !== 'undefined' ? index : 0
    readonly property int _totalCount: ((!!ListView.view) && (!!ListView.view.model)) ? (ListView.view.model.count || ListView.view.model.length || 0) : 0
    readonly property bool _useCollapsedLayout: LuneOSRadioButton.useCollapsedLayout
    readonly property bool _reallyUseCollapsedLayout: _useCollapsedLayout && _totalCount>0 && index >= 0

    font.family: "Prelude"
    font.pixelSize: FontUtils.sizeToPixels("medium")
    font.weight: Font.Light

    //! [contentItem]
    contentItem: Text {
        leftPadding: control.indicator && control.indicator.visible && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.indicator.visible && control.mirrored ? control.indicator.width + control.spacing : 0

        text: control.text
        font: control.font
        color: control.enabled ? "#26282a" : "#bdbebf"
        elide: Text.ElideRight
        visible: control.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    //! [contentItem]

    //! [indicator]
    indicator: RadioIndicatorLuneOS {
        x: text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding) : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        control: control
        visible: !_reallyUseCollapsedLayout
    }
    //! [indicator]

    //! [background]
    background: BorderImage {
        property string _positionButton: _totalCount === 1 ? "single" :
                                            _index === 0 ? "first" :
                                               _index === _totalCount-1 ? "last" : "middle"
        property string _pressed: (control.pressed || control.checked) ? "-pressed" : ""
        source: "images/radiobutton-"+_positionButton+_pressed+".png"
        width: control.width; height: control.height
        border.left: 5; border.top: 5
        border.right: 5; border.bottom: 5
        visible: _reallyUseCollapsedLayout
    }
    //! [background]
}
