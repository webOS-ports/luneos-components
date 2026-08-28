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
    leftPadding: 20; rightPadding: 20
    topPadding: 10; bottomPadding: 10

    readonly property bool _appMenuStyle: LuneOSMenu.appMenuStyle

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

        ScrollIndicator.vertical: ScrollIndicator {}
    }
    //! [contentItem]

    //! [background]
    background: Item {
        implicitWidth: _appMenuStyle ? appMenuStyleBg.implicitWidth : generalStyleBg.implicitWidth
        implicitHeight: _appMenuStyle ? appMenuStyleBg.implicitHeight : generalStyleBg.implicitHeight
        BorderImage {
            id: generalStyleBg
            source: "images/menu-background.png"
            border.left: 20; border.top: 20
            border.right: 20; border.bottom: 20
            visible: !_appMenuStyle
            anchors.fill: parent
        }
        Rectangle {
            id: appMenuStyleBg
            radius: Units.gu(0.4)
            color: "#313131"
            visible: _appMenuStyle
            anchors.fill: parent
        }
    }
    //! [background]
}
