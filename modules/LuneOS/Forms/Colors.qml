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

pragma Singleton
import QtQuick 2.9

/*
 * The colours of a light, settings-style page, by what they are for.
 *
 * Every one of these was written as a literal, again and again: Settings
 * alone had #666666 sixty-three times. The values are the ones the apps
 * already used, so moving a literal over to its name changes nothing on
 * screen. Buttons keep LuneOSButton's own colours (affirmativeColor,
 * negativeColor, secondaryColor); error below is the same red as
 * negativeColor, for text.
 */
QtObject {
    // The page: the flat grey behind everything, and the gradient a page
    // draws from top to bottom
    readonly property color pageBackground: "#D8D8D8"
    readonly property color pageGradientTop: "#D8D8D8"
    readonly property color pageGradientBottom: "#888888"

    // Text
    readonly property color text: "#2a2929"
    // Help text, sublabels, a placeholder value
    readonly property color secondaryText: "#666666"
    // Something went wrong; the same red as LuneOSButton.negativeColor
    readonly property color error: "#be0003"

    // The two-tone rule between rows: dark line over light line
    readonly property color ruleDark: "#ADADAD"
    readonly property color ruleLight: "#ECECEC"

    // A light text field
    readonly property color fieldBackground: "#ffffff"
    readonly property color fieldDisabledBackground: "#e4e4e4"
    readonly property color fieldBorder: "#9a9a9a"

    // A notice about the page as a whole (a missing service, a failed send)
    readonly property color noticeBackground: "#f4ecd0"
    readonly property color noticeBorder: "#c9b980"
    readonly property color noticeText: "#5a4b16"
    readonly property color noticeSecondaryText: "#7a6a30"
}
