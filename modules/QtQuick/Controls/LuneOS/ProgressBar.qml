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

T.ProgressBar {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentItem.implicitHeight + topPadding + bottomPadding)

    //! [contentItem]
    contentItem: Item {
        implicitHeight: 18
        implicitWidth: 200

        BorderImage {
            source: "images/progress-bar-inner.png"
            border.left: 4; border.top: 8
            border.right: 4; border.bottom: 8

            anchors.verticalCenter: parent.verticalCenter
            scale: control.mirrored ? -1 : 1
            height: 18
            width: control.indeterminate ? control.availableWidth/3 : (control.position*control.availableWidth)
            x: 0

            SequentialAnimation on x {
                running: control.indeterminate && control.enabled && control.visible
                loops: Animation.Infinite
                PropertyAnimation { to: 2*control.availableWidth/3; duration: 500 }
                PropertyAnimation { to: 0; duration: 500 }
            }
        }
    }
    //! [contentItem]

    //! [background]
    background: BorderImage {
        source: "images/progress-bar.png"
        border.left: 4; border.top: 8
        border.right: 4; border.bottom: 8

        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: 18
    }
    //! [background]
}
