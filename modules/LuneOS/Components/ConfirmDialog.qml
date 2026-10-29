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

Dialog {
    id: confirmDialog

    message: "Please confirm"
    // Tall enough for the title, the message and both buttons. It used to be
    // shorter, which only looked right while the two buttons were drawn on
    // top of one another and the message was behind them.
    dialogHeight: Units.gu(19)
    dialogWidth: Units.gu(30)

    // The buttons' words: say what happens ("Delete"), as the guidelines
    // ask, rather than "OK".
    property string acceptText: "OK"
    property string rejectText: "Cancel"
    // A red accept button, for something that cannot be undone.
    property bool destructive: false

    signal accepted();
    signal rejected();

    // What ask() was given to run, until the dialog is answered
    property bool _asked: false
    property var _onAccepted: null
    property var _onRejected: null

    /*
     * Opens the dialog and runs what the answer is for, in one call:
     *
     *   confirm.ask({ title: "Delete Album", message: "Are you sure...?",
     *                 acceptText: "Delete", destructive: true,
     *                 onAccepted: function() { ... } });
     *
     * What is left out is reset: no title or message, "OK" and "Cancel",
     * not destructive. A rejectText of "" makes it a notice with one
     * button. The dialog is closed before the function runs, so that may
     * ask() again.
     */
    function ask(options) {
        var o = options || {};
        title = o.title !== undefined ? o.title : "";
        message = o.message !== undefined ? o.message : "";
        acceptText = o.acceptText !== undefined ? o.acceptText : "OK";
        rejectText = o.rejectText !== undefined ? o.rejectText : "Cancel";
        destructive = o.destructive === true;
        _onAccepted = typeof o.onAccepted === "function" ? o.onAccepted : null;
        _onRejected = typeof o.onRejected === "function" ? o.onRejected : null;
        _asked = true;
        open();
    }

    function _answer(run) {
        _asked = false;
        _onAccepted = null;
        _onRejected = null;
        close();
        if (run)
            run();
    }

    onAccepted: if (_asked) _answer(_onAccepted)
    onRejected: if (_asked) _answer(_onRejected)

    Row {
        DialogButton {
            objectName: "confirmAcceptButton"
            text: confirmDialog.acceptText
            color: confirmDialog.destructive ? "#be0003" : "#4B4B4B"
            fontcolor: "white"
            buttonWidth: Units.gu(26.0)

            onClicked: confirmDialog.accepted();
        }
    }
    // Not there for a notice (rejectText "")
    Row {
        visible: confirmDialog.rejectText !== ""
        DialogButton {
            objectName: "confirmRejectButton"
            text: confirmDialog.rejectText
            color: "white"
            fontcolor: "#292929"
            buttonWidth: Units.gu(26.0)

            onClicked: confirmDialog.rejected();
        }
    }
}
