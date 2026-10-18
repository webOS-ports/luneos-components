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
 * The letters down the right edge of a long list: slide a finger along
 * them to jump to the names starting with that letter, with the letter
 * shown large while doing so.
 *
 *     FastScroller {
 *         anchors { right: list.right; top: list.top; bottom: list.bottom }
 *         view: list
 *         sections: names.map(n => FileLists.fold(n).charAt(0).toUpperCase())
 *     }
 *
 * "sections" are the list's items' letters, in list order - "#" for
 * anything that is not A to Z; the scroller moves "view" (a ListView or a
 * GridView) to the first item with the letter under the finger. It only
 * shows for a list long enough to need it ("minimumCount").
 */
Item {
    id: scroller

    property var view
    property var sections: []
    property int minimumCount: 40
    property color textColor: "#888888"
    property color accentColor: "#3a87c8"

    readonly property var _letters: {
        var present = {};
        for (var i = 0; i < sections.length; i++)
            present[sections[i]] = true;
        return "#ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("").filter(function(c) { return present[c]; });
    }
    property string _current: ""

    width: Units.gu(3)
    visible: sections.length > minimumCount && _letters.length > 1

    function _jump(y) {
        if (_letters.length === 0)
            return;
        var i = Math.max(0, Math.min(_letters.length - 1, Math.floor(y / height * _letters.length)));
        var letter = _letters[i];
        if (letter === _current)
            return;
        _current = letter;
        for (var j = 0; j < sections.length; j++) {
            if (sections[j] === letter) {
                if (view.positionViewAtIndex)
                    view.positionViewAtIndex(j, ListView.Beginning);
                return;
            }
        }
    }

    Column {
        anchors.fill: parent
        Repeater {
            model: scroller._letters
            delegate: Text {
                required property string modelData
                width: scroller.width
                height: scroller.height / Math.max(1, scroller._letters.length)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: scroller.textColor
                font.pixelSize: Math.min(FontUtils.sizeToPixels("x-small"), height * 0.9)
            }
        }
    }

    MouseArea {
        id: touch
        objectName: "fastScrollerTouch"
        anchors.fill: parent
        preventStealing: true
        onPressed: function(event) { scroller._current = ""; scroller._jump(event.y); }
        onPositionChanged: function(event) { scroller._jump(event.y); }
    }

    Rectangle {
        visible: touch.pressed && scroller._current !== ""
        anchors.right: parent.left
        anchors.rightMargin: Units.gu(2)
        y: Math.max(0, Math.min(scroller.height - height, touch.mouseY - height / 2))
        width: Units.gu(8)
        height: width
        radius: width / 2
        color: scroller.accentColor
        Text {
            anchors.centerIn: parent
            text: scroller._current
            color: "white"
            font.pixelSize: Units.gu(4)
            font.weight: Font.Bold
        }
    }
}
