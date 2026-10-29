/*
 * (c) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12

/*
 * A picture that may take a moment, or not come at all - a thumbnail, a
 * cover: a dark tile with a faint placeholder sign until the picture is
 * there. broken() says the picture could not be loaded (its file gone),
 * for an app to make it again.
 *
 *   PlaceholderImage { source: thumb; placeholder: Qt.resolvedUrl("images/empty-thumbnail.png") }
 */
Item {
    id: holder

    property alias source: picture.source
    property url placeholder
    // The sign's share of the tile, and how faint it is
    property real placeholderScale: 0.4
    property real placeholderOpacity: 0.35
    property color backgroundColor: "#2b2b2b"
    // Fill the tile, cut to it; else fit inside it
    property bool crop: true
    property real aspectRatio: picture.implicitHeight>0 ? picture.implicitWidth/picture.implicitHeight : 1
    readonly property alias status: picture.status
    signal broken()

    Rectangle {
        anchors.fill: parent
        color: holder.backgroundColor
    }
    Image {
        objectName: "placeholder"
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * holder.placeholderScale
        height: width
        sourceSize: Qt.size(Math.ceil(width), Math.ceil(height))
        source: holder.placeholder
        opacity: holder.placeholderOpacity
        visible: picture.status !== Image.Ready
    }
    Image {
        id: picture
        objectName: "picture"
        anchors.fill: parent
        asynchronous: true
        autoTransform: true
        cache: true
        fillMode: holder.crop ? Image.PreserveAspectCrop : Image.PreserveAspectFit
        clip: true
        sourceSize: Qt.size(Math.ceil(width), Math.ceil(height))
        onStatusChanged: if (status === Image.Error) holder.broken()
    }
}
