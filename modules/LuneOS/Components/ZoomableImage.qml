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

import QtQuick

/*
 * A picture filling its item: fitted, pinched to zoom in (up to three times the
 * fitted size) and dragged about, a double tap zooms in on that spot or
 * back out. A single tap is told (tapped()), a moment later, so that it is
 * not the first half of a double tap.
 *
 *   ZoomableImage { anchors.fill: parent; source: picture; onTapped: bars.toggle() }
 */
Flickable {
    id: flick

    property url source
    readonly property bool zoomed: contentWidth > width + 1 || contentHeight > height + 1
    readonly property int status: picture.status
    property real maxZoom: 3
    signal tapped()

    contentWidth: width
    contentHeight: height
    clip: true
    interactive: zoomed
    boundsBehavior: Flickable.StopAtBounds

    function reset() {
        resizeContent(width, height, Qt.point(0, 0));
        contentX = 0;
        contentY = 0;
    }

    function zoomAt(point) {
        if (zoomed) {
            reset();
            return;
        }
        resizeContent(width * 2, height * 2, point);
        returnToBounds();
    }

    onWidthChanged: reset()
    onHeightChanged: reset()
    onSourceChanged: reset()

    PinchArea {
        width: Math.max(flick.contentWidth, flick.width)
        height: Math.max(flick.contentHeight, flick.height)

        property real startWidth
        property real startHeight
        onPinchStarted: {
            startWidth = flick.contentWidth;
            startHeight = flick.contentHeight;
        }
        onPinchUpdated: function(pinch) {
            flick.contentX += pinch.previousCenter.x - pinch.center.x;
            flick.contentY += pinch.previousCenter.y - pinch.center.y;
            var s = Math.max(1, Math.min(flick.maxZoom, startWidth * pinch.scale / flick.width));
            flick.resizeContent(flick.width * s, flick.height * s, pinch.center);
        }
        onPinchFinished: flick.returnToBounds()

        Image {
            id: picture
            objectName: "fullPicture"
            width: flick.contentWidth
            height: flick.contentHeight
            asynchronous: true
            autoTransform: true
            fillMode: Image.PreserveAspectFit
            smooth: true
            // Decoded at twice the screen: sharp when zoomed, bounded in
            // memory however big the file.
            sourceSize: Qt.size(Math.ceil(flick.width * 2), Math.ceil(flick.height * 2))
            source: flick.source

            MouseArea {
                anchors.fill: parent
                onClicked: tapTimer.restart()
                onDoubleClicked: function(mouse) {
                    tapTimer.stop();
                    flick.zoomAt(Qt.point(mouse.x, mouse.y));
                }
            }
        }
    }

    Timer {
        id: tapTimer
        interval: 260
        onTriggered: flick.tapped()
    }
}
