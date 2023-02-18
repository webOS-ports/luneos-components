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
import QtQuick.Templates 2.4 as T

import LunaNext.Common 0.1
import QtQml.Models 2.2

T.MenuItem {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             Math.max(contentItem.implicitHeight,
                                      indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    readonly property int _index: ObjectModel.index
    readonly property int _totalCount: ListView.view.model.count
    readonly property bool _appMenuStyle: ListView.view._appMenuStyle

    font.family: "Prelude"
    font.pixelSize: FontUtils.sizeToPixels("medium")

    //! [contentItem]
    contentItem: Text {
        leftPadding: control.checkable && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.checkable && control.mirrored ? control.indicator.width + control.spacing : 0

        text: control.text
        font: control.font
        color: (_appMenuStyle ? (!control.enabled) : control.enabled) ? "#26282a" : "#bdbebf"
        visible: control.text
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
    //! [contentItem]

    //! [indicator]
    indicator: Image {
        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2

        visible: control.checked
        source: control.checkable ? "images/checkmark.png" : ""
    }
    //! [indicator]

    //! [background]
    background: Item {
        implicitWidth: 200
        implicitHeight: 40

        // Show a separator between items
        Rectangle {
            y: parent.height-1
            height: 1
            width: parent.width
            color: '#ADADAD'
            visible: _index < _totalCount - 1
        }
        Rectangle {
            y: parent.height
            height: 1
            width: parent.width
            color: '#ECECEC'
            visible: _index < _totalCount - 1
        }
    }
    //! [background]
}
