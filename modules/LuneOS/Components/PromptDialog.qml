/*
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
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

/*
 * A line of text asked for, with OK and Cancel - or the words given:
 *
 *   prompt.ask({ title: "Rename Album", text: album.name, acceptText: "Rename",
 *                valid: function(t) { return t.trim() !== ""; },
 *                onAccepted: function(t) { rename(album, t); } });
 *
 * The field has the focus and its text selected when the dialog opens. A
 * text that valid() refuses is not taken: the field flashes red. The
 * dialog keeps clear of the keyboard by default.
 */
Dialog {
    id: dialog

    property string defaultValue: ""
    property string acceptText: "OK"
    property string rejectText: "Cancel"
    // function(text): whether the text may be taken; null takes any
    property var valid: null
    property alias text: input.text
    readonly property alias field: input

    // Tall enough for a title, a message, the field and both buttons
    dialogHeight: fittedHeight
    dialogWidth: Units.gu(30)
    keepClearOfKeyboard: true

    signal accepted(string text);
    signal rejected();

    // What ask() was given to run, until the dialog is answered
    property bool _asked: false
    property var _onAccepted: null
    property var _onRejected: null

    /*
     * Opens the dialog and runs what the answer is for, in one call; the
     * keys are the properties' names, and onAccepted gets the text. What is
     * left out is reset: no title or message, an empty field, "OK" and
     * "Cancel", any text taken. The dialog is closed before the function
     * runs.
     */
    function ask(options) {
        var o = options || {};
        title = o.title !== undefined ? o.title : "";
        message = o.message !== undefined ? o.message : "";
        input.text = o.text !== undefined ? o.text : "";
        acceptText = o.acceptText !== undefined ? o.acceptText : "OK";
        rejectText = o.rejectText !== undefined ? o.rejectText : "Cancel";
        valid = typeof o.valid === "function" ? o.valid : null;
        _onAccepted = typeof o.onAccepted === "function" ? o.onAccepted : null;
        _onRejected = typeof o.onRejected === "function" ? o.onRejected : null;
        _asked = true;
        open();
    }

    // Takes the text, unless valid() refuses it
    function accept() {
        var t = input.typedText();
        if (valid && !valid(t)) {
            flash.restart();
            return;
        }
        accepted(t);
        if (_asked) {
            var run = _onAccepted;
            _clear();
            close();
            if (run)
                run(t);
        }
    }

    function reject() {
        rejected();
        if (_asked) {
            var run = _onRejected;
            _clear();
            close();
            if (run)
                run();
        }
    }

    function _clear() {
        _asked = false;
        _onAccepted = null;
        _onRejected = null;
    }

    onVisibleChanged: {
        if (visible) {
            input.textInput.forceActiveFocus();
            input.textInput.selectAll();
        }
    }

    Row {
        spacing: Units.gu(0.5)
        DialogLineInput {
            id: input
            objectName: "promptField"
            text: dialog.defaultValue
            // In its row: DialogLineInput lifts itself two grid units, which
            // put the field over the title
            anchors.verticalCenterOffset: 0

            onAccepted: dialog.accept()

            // A text valid() refused
            Rectangle {
                anchors.fill: parent
                color: "#be0003"
                opacity: 0
                radius: Units.gu(0.5)
                SequentialAnimation on opacity {
                    id: flash
                    running: false
                    NumberAnimation { to: 0.35; duration: 120 }
                    NumberAnimation { to: 0; duration: 400 }
                }
            }
        }
    }
    Row
    {
        DialogButton {
            id: okButton
            objectName: "promptAcceptButton"
            text: dialog.acceptText
            onClicked: dialog.accept()
            color: "#171717"
            fontcolor: "white"
            buttonWidth: Units.gu(26.0)

        }
    }
    Row {
        DialogButton {
            objectName: "promptRejectButton"
            text: dialog.rejectText
            onClicked: dialog.reject()
            color: "transparent"
            fontcolor: "#444444"
            buttonWidth: Units.gu(26.0)
        }
    }
}
