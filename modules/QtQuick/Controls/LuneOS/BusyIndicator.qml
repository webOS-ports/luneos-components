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

T.BusyIndicator {
    id: control

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding

    padding: 6

    //! [contentItem]
    //! The legacy spinner's first frame, turned on the render thread. Its GIF
    //! was eight frames of the same ring a 45 degree step apart, and an
    //! AnimatedImage only steps while the main thread is free - so a page
    //! busy loading, which is when a spinner is shown, froze it. An Animator
    //! keeps turning regardless (Camera measured 857 frames during a 3s
    //! block). It turns smoothly at the GIF's own speed, one turn in 800ms,
    //! rather than in steps.
    contentItem: Item {
        implicitWidth: ring.implicitWidth
        implicitHeight: ring.implicitHeight
        opacity: control.running ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { OpacityAnimator { duration: 250 } }

        Image {
            id: ring
            anchors.centerIn: parent
            source: "images/spinner-light.png"

            RotationAnimator on rotation {
                running: control.running && control.visible
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 800
            }
        }
    }
    //! [contentItem]
}
