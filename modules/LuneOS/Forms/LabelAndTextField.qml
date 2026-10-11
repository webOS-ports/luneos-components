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

import QtQuick 2.9
import QtQuick.Controls 2.2
// Units & font sizes
import LunaNext.Common 0.1

/*
 * A label with an editable field on the right - the textfield-group rows the
 * Mojo settings apps used wherever something had to be typed in rather than
 * picked, as in the legacy Wi-Fi app's static IP scene.
 *
 * "edited" only fires for a change the user made, so binding "text" to a
 * setting cannot write it straight back. "committed" fires once the user is
 * done - Enter, or the field losing focus - and only if they changed
 * something: for a setting that costs a round trip to write (Phone's call
 * forwarding goes to the network), rather than one write per keystroke.
 */
Item {
    id: labelAndTextField

    property alias label: labelName.text
    property alias text: field.text
    property alias placeholderText: field.placeholderText
    property alias inputMethodHints: field.inputMethodHints
    property alias readOnly: field.readOnly
    // Drawn by the field itself rather than by the page, so a row cannot be
    // left looking valid while the button that depends on it is disabled.
    property bool acceptable: true
    // Narrower leaves the label more of the row: a phone number needs less
    // room than a Wi-Fi passphrase
    property real fieldWidth: Units.gu(24)

    signal edited(string text)
    signal committed(string text)

    property bool _changed: false

    // Both, so the row is sized correctly whether it is laid out by a
    // Column (which reads height) or by a GroupBox (which reads implicit).
    // As wide as what it sits in, like LabelAndSwitch: a Column (FormGroup's)
    // leaves an item with no width out of its layout
    width: parent ? parent.width : implicitWidth
    height: Units.gu(6)
    implicitHeight: Units.gu(6)

    Label {
        id: labelName
        anchors.left: parent.left
        anchors.right: field.left
        anchors.rightMargin: Units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        font.pixelSize: FontUtils.sizeToPixels("16pt")
    }

    FormTextField {
        id: field
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: labelAndTextField.fieldWidth
        height: Units.gu(5)

        horizontalAlignment: Text.AlignRight
        font.pixelSize: FontUtils.sizeToPixels("16pt")
        acceptable: labelAndTextField.acceptable

        onTextEdited: {
            labelAndTextField._changed = true;
            labelAndTextField.edited(text);
        }
        onEditingFinished: {
            if (!labelAndTextField._changed)
                return;
            labelAndTextField._changed = false;
            labelAndTextField.committed(text);
        }
    }
}
