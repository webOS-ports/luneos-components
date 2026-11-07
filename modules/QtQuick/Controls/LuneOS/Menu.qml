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
import QtQuick.Controls.LuneOS 2.0
import QtQuick.Templates 2.4 as T

import LunaNext.Common 0.1

T.Menu {
    id: control

    /*
     * As wide as its widest entry.
     *
     * The content item is a vertical ListView, and such a list's contentWidth
     * is the width of its viewport rather than of its widest delegate, so
     * asking it left every menu as wide as its background image with anything
     * longer cut short. Menu.contentWidth would be the thing to use, but it
     * stays at zero while the content item is a list of our own.
     *
     * Measured rather than bound: reaching for an item creates it, and an item
     * being created while the menu is working out how wide it is would have
     * the menu ask itself.
     */
    property real _widestItem: 0

    function _measureItems() {
        var widest = 0;
        for (var i = 0; i < control.count; ++i) {
            var item = control.itemAt(i);
            if (item && item.implicitWidth > widest)
                widest = item.implicitWidth;
        }
        control._widestItem = widest;
    }

    // Measured as the menu is about to be shown, by which point its items
    // exist. Reaching for them while the menu is still being built leaves the
    // list half-made and nothing draws at all.
    onAboutToShow: _measureItems()

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            _widestItem + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentItem ? contentItem.implicitHeight : 0) + topPadding + bottomPadding

    margins: 0
    leftPadding: _appMenuStyle ? Math.round(1 * _px) : 20
    rightPadding: _appMenuStyle ? Math.round(10 * _px) : 20
    topPadding: _appMenuStyle ? 0 : 10
    bottomPadding: _appMenuStyle ? Math.round(20 * _px) : 10

    readonly property bool _appMenuStyle: LuneOSMenu.appMenuStyle

    /*
     * The app menu is webOS 3.0's (enyo.AppMenu in the Onyx theme), laid out
     * in its CSS pixels: those of the TouchPad, where a grid unit is ten of
     * them. Onyx's frame (appmenu.png, sliced 12 24 20 24) starts 10px left
     * of the menu's edge (left: -10px) and its rows 13px into the frame's
     * 24px left border; they run to 14px into the right one and to the top
     * of the frame, and the frame closes 20px under the last of them. It is
     * at least 210px wide.
     */
    readonly property real _px: Units.gridUnit / 10

    //! [contentItem]
    contentItem: ListView {
        implicitHeight: contentHeight
        implicitWidth: contentWidth
        model: control.contentModel
        // TODO: improve this?
        interactive: T.ApplicationWindow.window ? contentHeight > T.ApplicationWindow.window.height : false
        clip: true
        keyNavigationWraps: false
        currentIndex: -1

        property bool _appMenuStyle: control._appMenuStyle
        property real _px: control._px

        ScrollIndicator.vertical: ScrollIndicator {}
    }
    //! [contentItem]

    //! [background]
    background: Item {
        // The app menu's frame is at least 210px wide, 10px of it left of the menu
        implicitWidth: _appMenuStyle ? Math.round(200 * control._px) : generalStyleBg.implicitWidth
        implicitHeight: _appMenuStyle ? 0 : generalStyleBg.implicitHeight
        BorderImage {
            id: generalStyleBg
            source: "images/menu-background.png"
            border.left: 20; border.top: 20
            border.right: 20; border.bottom: 20
            visible: !_appMenuStyle
            anchors.fill: parent
        }
        // Onyx's images-1.5/appmenu.png (120x240, sliced 18 36 30 36), made
        // at the 1.5 scale it is drawn for and scaled to the CSS pixel here, so
        // that the slices are Onyx's 12 24 20 24
        BorderImage {
            id: appMenuStyleBg
            readonly property real _scale: control._px / 1.5
            visible: _appMenuStyle
            x: -Math.round(10 * control._px)
            width: (parent.width - x) / _scale
            height: parent.height / _scale
            scale: _scale
            transformOrigin: Item.TopLeft
            smooth: true
            source: "images/appmenu.png"
            border.left: 36; border.top: 18
            border.right: 36; border.bottom: 30
        }
    }
    //! [background]
}
