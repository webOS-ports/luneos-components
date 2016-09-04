/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the QtWebEngine module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
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

import QtQuick 2.5
import QtQuick.Controls 1.4 as Controls
import QtQuick.Controls.Styles 1.4

import LunaNext.Common 0.1

Controls.Menu {
    id: menu
    signal done()

    Component.onCompleted: {
        console.log("parent: "+menu.parent);
    }

    // Use private API for now
    onAboutToHide: doneTimer.start();

    // WORKAROUND On Mac the Menu may be destroyed before the MenuItem
    // is actually triggered (see qtbase commit 08cc9b9991ae9ab51)
    Timer {
        id: doneTimer
        interval: 100
        onTriggered: menu.done()
    }

    style: MenuStyle {
        padding.left: 10
        padding.right: 10
        padding.top: 10
        padding.bottom: 10

        frame: BorderImage {
            source: Qt.resolvedUrl("images/popup-bg.png")
            border { left: 18; top: 18; right: 18; bottom: 18 }
        }

        font {
            pixelSize: FontUtils.sizeToPixels("large")
            family: "Prelude"
        }
        itemDelegate.label: Text {
            color: styleData.enabled ? "black" : "grey"
            text: styleData.text
            font {
                pixelSize: FontUtils.sizeToPixels("large")
                family: "Prelude"
            }
        }
        itemDelegate.background: Rectangle {
            color:  "dodgerblue"
            visible: styleData.selected && styleData.enabled
            radius: 8
        }
    }
}
