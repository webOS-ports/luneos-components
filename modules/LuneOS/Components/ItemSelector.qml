/*
 * Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; see the file COPYING.  If not, see
 * <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.0
import LunaNext.Common 0.1

MouseArea {
    // To avoid conflicting with ListView.model when inside ListView context.
    property QtObject selectorModel: model
    anchors.fill: parent
    onClicked: selectorModel.reject() // Tofe: not great

    Rectangle {
        id: mainRect

        clip: true
        width: Units.gu(30)
        height: Math.min(listView.contentItem.height + listView.anchors.topMargin + listView.anchors.bottomMargin
                         , Math.max(selectorModel.elementRect.y, parent.height - selectorModel.elementRect.y - selectorModel.elementRect.height))
        x: (selectorModel.elementRect.x + Units.gu(20.0) > parent.width) ? parent.width - Unit.gu(20.0) : selectorModel.elementRect.x
        y: (selectorModel.elementRect.y + selectorModel.elementRect.height + height < parent.height ) ? selectorModel.elementRect.y + selectorModel.elementRect.height
                                                         : selectorModel.elementRect.y - height;
        radius: 5
        color: "#DDDDDD"
        opacity: 0.8

        ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: Units.gu(1.0)
            spacing: Units.gu(0.5)
            model: selectorModel.items


            delegate: Rectangle {
                color: model.selected ? "gold" : "#DDDDDD"
                height: Units.gu(3)
                width: parent.width //width: myText1.contentWidth //.width

                Text {
                    id: myText1
                    anchors.left: parent.left
                    text: model.text
                    color: model.enabled ? "#333333" : "gainsboro"
                    font.pixelSize: FontUtils.sizeToPixels("12pt")
                    font.family: "Prelude"

                }

                MouseArea {
                    anchors.fill: parent
                    enabled: model.enabled
                    onClicked:          selectorModel.accept(model.index)
                    }
            }

            section.property: "group"
            section.delegate: Rectangle {
                height: Units.gu(3.0)
                width: parent.width
                color: "silver"
                Text {
                    id: myText2
                    anchors.left: parent.left
                    text: section
                    font.italic: true
                    color: "#333333"
                    font.pixelSize: FontUtils.sizeToPixels("12pt")
                    font.family: "Prelude"
                }
            }
        }
    }
}
