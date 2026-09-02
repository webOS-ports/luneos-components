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
import QtQml.Models 2.2

import QtQuick.Controls.LuneOS 2.0

T.TabButton {
    id: control

    implicitWidth: Math.max(textContent.contentWidth,imageContent.implicitWidth) + leftPadding + rightPadding
    implicitHeight: Math.max(textContent.contentHeight,imageContent.implicitHeight) + topPadding + bottomPadding
    baselineOffset: contentItem.y + contentItem.baselineOffset

    padding: 6

    readonly property url _image: LuneOSButton.image

    //! [contentItem]
    // A tab may carry an image, a label, or -- as the webOS apps do -- an icon
    // above a small caption. Setting both used to hide the text; now they stack.
    readonly property bool _hasImage: _image.toString() !== ""
    readonly property bool _hasText: control.text !== ""
    readonly property bool _stacked: _hasImage && _hasText

    contentItem: Item {
        Image {
            id: imageContent
            visible: control._hasImage
            source: _image

            height: control._stacked ? Math.round(parent.height * 0.6) : parent.height
            width: height
            fillMode: Image.PreserveAspectCrop
            clip: true
            verticalAlignment: (control.checked||control.down) ? Image.AlignBottom : Image.AlignTop
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }
        Text {
            id: textContent
            visible: control._hasText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: control._stacked ? imageContent.bottom : parent.top
            anchors.bottom: parent.bottom

            text: control.text
            // Assigning the whole font group and then individual members is an
            // error, so every member is set here. The size is left as the
            // caller set it: a font given by pointSize reports pixelSize as -1,
            // and scaling that yields an invalid size and no text at all.
            font.family: control.font.family
            font.bold: control.font.bold
            font.italic: control.font.italic
            font.weight: control.font.weight
            font.pixelSize: control.font.pixelSize
            // A caption under an icon reads as a label rather than body text.
            font.capitalization: control._stacked ? Font.AllUppercase : Font.MixedCase
            elide: Text.ElideRight
            opacity: enabled ? 1 : 0.3
            color: !control.checked ? "#ffffff" : control.down ? "#26282a" : "#353637"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: control._stacked ? Text.AlignTop : Text.AlignVCenter
        }
    }
    //! [contentItem]

    //! [background]
    background: Rectangle {
        // The selected tab now carries the same blue as a Switch in its "on"
        // state (images/toggle-button-on.png), which is a lighter, less
        // saturated blue than the #2071bb this used to be - side by side the
        // old one read as a different, darker accent.
        color: control.checked ? "#4585b8" : "#343434"
        height: control.height

        BorderImage {
            anchors.fill: parent
            source: "images/toolbar.png"
            border.left: 2; border.top: 2
            border.right: 2; border.bottom: 2
        }
    }
    //! [background]
}
