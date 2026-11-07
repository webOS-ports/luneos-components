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
                                      // The app menu's check is drawn over the row, as Onyx's background image is
                                      indicator && !_appMenuStyle ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    readonly property int _index: ObjectModel.index
    readonly property int _totalCount: ListView.view.model.count
    readonly property bool _appMenuStyle: ListView.view._appMenuStyle

    /*
     * In the app menu, a row of enyo.AppMenu (Onyx's AppMenuItem): 10px above
     * and below a 16px caption on a 22px line, 8px of the row's width left of
     * it and 10px right; a 1px gap over every row but the first and Onyx's
     * 2px divider (appmenu-divider.png) under every row but the last;
     * appmenu-highlight.png while held, the whole row at half opacity when
     * disabled. In webOS 3.0's CSS pixels, ten to a grid unit.
     */
    readonly property real _px: ListView.view._px
    readonly property bool _first: _index === 0
    readonly property bool _last: _index === _totalCount - 1

    font.family: "Prelude"
    font.pixelSize: _appMenuStyle ? Math.round(16 * _px) : FontUtils.sizeToPixels("medium")

    topPadding: _appMenuStyle ? Math.round((_first ? 10 : 11) * _px) : undefined
    bottomPadding: _appMenuStyle ? Math.round((_last ? 10 : 12) * _px) : undefined
    leftPadding: _appMenuStyle ? Math.round(8 * _px) : undefined
    rightPadding: _appMenuStyle ? Math.round(10 * _px) : undefined
    opacity: _appMenuStyle && !enabled ? 0.5 : 1

    //! [contentItem]
    contentItem: Text {
        // The app menu's check is Onyx's MenuCheckItem's: at the end of the
        // caption, which stops 34px short of the end of the row for it
        leftPadding: _appMenuStyle ? (control.checkable && control.mirrored ? Math.round(34 * control._px) : 0)
                                   : control.checkable && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: _appMenuStyle ? (control.checkable && !control.mirrored ? Math.round(34 * control._px) : 0)
                                    : control.checkable && control.mirrored ? control.indicator.width + control.spacing : 0

        text: control.text
        font: control.font
        color: _appMenuStyle ? "white" : control.enabled ? "#26282a" : "#bdbebf"
        lineHeightMode: _appMenuStyle ? Text.FixedHeight : Text.ProportionalHeight
        lineHeight: _appMenuStyle ? Math.round(22 * _px) : 1.0
        elide: _appMenuStyle ? Text.ElideRight : Text.ElideNone
        visible: control.text
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }
    //! [contentItem]

    //! [indicator]
    indicator: Image {
        // In the app menu, Onyx's images-1.5/checkmark.png at its 32x32 CSS
        // size, centred on the caption at its end
        readonly property bool _atEnd: _appMenuStyle !== control.mirrored
        x: _atEnd ? control.width - width - control.rightPadding : control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: _appMenuStyle ? Math.round(32 * control._px) : implicitWidth
        height: _appMenuStyle ? width : implicitHeight

        visible: control.checked
        source: control.checkable ? "images/checkmark.png" : ""
    }
    //! [indicator]

    //! [background]
    background: Item {
        implicitWidth: _appMenuStyle ? 0 : 200
        implicitHeight: _appMenuStyle ? 0 : 40

        // Show a separator between items
        Rectangle {
            y: parent.height-1
            height: 1
            width: parent.width
            color: '#ADADAD'
            visible: !_appMenuStyle && _index < _totalCount - 1
        }
        Rectangle {
            y: parent.height
            height: 1
            width: parent.width
            color: '#ECECEC'
            visible: !_appMenuStyle && _index < _totalCount - 1
        }

        // The app menu's: held, Onyx's highlight, its 40x56 tile repeated
        // across the whole row, the gap over it included; and the divider
        Image {
            visible: _appMenuStyle && control.down
            anchors.fill: parent
            source: "images/appmenu-highlight.png"
            sourceSize: Qt.size(Math.round(40 * control._px), Math.round(56 * control._px))
            fillMode: Image.Tile
            horizontalAlignment: Image.AlignLeft
            verticalAlignment: Image.AlignTop
            clip: true
        }
        // Onyx's appmenu-divider.png, two lines: black at 40%, then white at
        // 8%. Drawn rather than stretched, as the 1.5 image here has three rows
        // that blur into two. Onyx gives the row border-style: solid and no
        // side widths, so the default 3px sides are border-image's empty
        // corners: the divider stops 3px short of either end
        Item {
            visible: _appMenuStyle && !_last
            anchors.left: parent.left
            anchors.leftMargin: Math.round(3 * control._px)
            anchors.right: parent.right
            anchors.rightMargin: Math.round(3 * control._px)
            anchors.bottom: parent.bottom
            height: Math.round(2 * control._px)
            Rectangle {
                id: dividerShade
                width: parent.width
                height: Math.max(1, Math.round(1 * control._px))
                color: Qt.rgba(0, 0, 0, 102 / 255)
            }
            Rectangle {
                y: dividerShade.height
                width: parent.width
                height: parent.height - dividerShade.height
                color: Qt.rgba(1, 1, 1, 20 / 255)
            }
        }
    }
    //! [background]
}
