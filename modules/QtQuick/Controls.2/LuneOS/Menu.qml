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
import QtQuick.Controls.LuneOS 2.0
import QtQuick.Templates 2.0 as T

import LunaNext.Common 0.1

T.Menu {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem ? contentItem.implicitWidth + leftPadding + rightPadding + 60 : 0)
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
