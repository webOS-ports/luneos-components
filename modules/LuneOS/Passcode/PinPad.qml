/* @@@LICENSE
*
*      Copyright (c) 2009-2013 LG Electronics, Inc.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* LICENSE@@@ */

import QtQuick 2.0
import LunaNext.Common 0.1

/*
 * The legacy PinDialpad: digits 1-9, 0 and a delete key, on the lock
 * screen's grid. keyAction() carries the digit, or "\b" for delete.
 * Taken from the shell's lock screen so other PIN entry can share it.
 */
Item {
    id: pinPad;

    width: Units.gu(320/10)
    height: gridDividers.height

    /*
     * The grid between the keys, as the legacy art drew it: under every row
     * and between the columns, a dark line with a faint light one below or
     * beside it. It was a 1280x920 image of 2-pixel lines, which, scaled to
     * a pad a quarter of that, averaged its lines away into the background;
     * drawn here they are a pixel each, on the keys' own boundaries, at any
     * size.
     */
    Item {
        id: gridDividers
        width: pinPad.width
        height: Math.round(width * 920 / 1280)
        property int topOffset: Units.gu(4/10)
        property int bottomOffset: Units.gu(6/10)

        readonly property real rowHeight: (height - topOffset - bottomOffset) / 4
        readonly property color darkLine: Qt.rgba(0, 0, 0, 0.4)
        readonly property color lightLine: Qt.rgba(1, 1, 1, 0.08)

        Repeater {
            model: 5
            Item {
                y: Math.round(gridDividers.topOffset + index * gridDividers.rowHeight)
                width: gridDividers.width
                height: 2
                Rectangle { width: parent.width; height: 1; color: gridDividers.darkLine }
                Rectangle { y: 1; width: parent.width; height: 1; color: gridDividers.lightLine }
            }
        }

        Repeater {
            model: 2
            Item {
                x: Math.round((index + 1) * gridDividers.width / 3)
                y: gridDividers.topOffset
                width: 2
                // Down to the line under the last row, not into the margin
                // below it, where the buttons under the pad begin.
                height: Math.round(gridDividers.topOffset + 4 * gridDividers.rowHeight) - y
                Rectangle { width: 1; height: parent.height; color: gridDividers.darkLine }
                Rectangle { x: 1; width: 1; height: parent.height; color: gridDividers.lightLine }
            }
        }
    }

    Grid {
        id: buttonGrid

        width: gridDividers.width
        height: gridDividers.height - gridDividers.topOffset - gridDividers.bottomOffset
        y: gridDividers.topOffset
        x:0
        columns: 3
        rows: 4
        spacing: 0

        PinButton { caption: "1"; width: buttonGrid.width/buttonGrid.columns; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        PinButton { caption: "2"; width: buttonGrid.width/buttonGrid.columns + 1; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        PinButton { caption: "3"; width: buttonGrid.width/buttonGrid.columns + 1; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        PinButton { caption: "4"; width: buttonGrid.width/buttonGrid.columns; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        PinButton { caption: "5"; width: buttonGrid.width/buttonGrid.columns + 1; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        PinButton { caption: "6"; width: buttonGrid.width/buttonGrid.columns + 1; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        PinButton { caption: "7"; width: buttonGrid.width/buttonGrid.columns; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        PinButton { caption: "8"; width: buttonGrid.width/buttonGrid.columns + 1; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        PinButton { caption: "9"; width: buttonGrid.width/buttonGrid.columns + 1; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        Rectangle { color: "transparent"; width: buttonGrid.width/buttonGrid.columns; height:buttonGrid.height/buttonGrid.rows;}
        PinButton { caption: "0"; width: buttonGrid.width/buttonGrid.columns + 1; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
        PinButton { imgSource: "images/icon-delete.png"; caption: "\b"; width: buttonGrid.width/buttonGrid.columns+1; height:buttonGrid.height/buttonGrid.rows; onAction: keyAction(text);}
    }

    signal keyAction(string keyText);
}
