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
import LunaNext.Common 0.1

/*
 * One end of a text selection, dragged. Drawn as the rest of LuneOS draws
 * them (its browser and web apps): legacy webOS's grey shield at 80%, the
 * one at the start above the line and turned over, pointing down at it, the
 * one at the end below, pointing up. Its point is on (tipX, tipY), given in
 * the parent's coordinates; the item around it is a finger's size.
 *
 * While it is dragged, dragged() gives where the point would now be: where
 * it was when the drag began plus how far the finger moved, so following the
 * selection as it changes cannot feed back into the drag.
 */
Item {
    id: handle

    property bool start: false
    property real tipX
    property real tipY
    readonly property bool dragging: drag.active

    signal dragStarted()
    signal dragged(real x, real y)
    signal dragFinished()

    width: Units.gu(5)
    height: Units.gu(4.5)
    x: tipX - width / 2
    y: start ? tipY - height : tipY

    ArtworkImage {
        objectName: "selectionHandleImage"
        anchors.horizontalCenter: parent.horizontalCenter
        // At the point: the bottom of the item for the start, the top for the end.
        y: handle.start ? parent.height - height : 0
        width: Units.gu(2.9)
        height: width * 27.7 / 32
        svg: Qt.resolvedUrl("images/selection-handle.svg")
        rotation: handle.start ? 180 : 0
        opacity: 0.8
    }

    DragHandler {
        id: drag
        target: null
        property real originX
        property real originY
        onActiveChanged: {
            if (active) {
                originX = handle.tipX;
                originY = handle.tipY;
                handle.dragStarted();
            } else {
                handle.dragFinished();
            }
        }
        onTranslationChanged: if (active)
                                  handle.dragged(originX + translation.x, originY + translation.y)
    }
}
