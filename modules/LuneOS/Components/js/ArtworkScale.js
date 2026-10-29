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


.pragma library

/*
 * Artwork drawn ahead into PNGs at one, two and three times its size at grid
 * unit 10 (the TouchPad, webOS's own scale), in <folder>/1x/, 2x/ and 3x/:
 * an app that ships PNGs rather than SVGs, as webOS's own apps did. The set
 * shown is the smallest that is not smaller than the screen needs, so a
 * picture is only ever made smaller, never blown up; at grid unit 10 it is
 * the drawn pixels themselves.
 *
 *   Image { source: ArtworkScale.url(Qt.resolvedUrl("images/"), "icn-delete", Units.gridUnit) }
 */

// 1, 2 or 3: the set for a grid unit. Five percent over a set is still that
// set, not worth twice the pixels.
function scale(gridUnit) {
    return Math.max(1, Math.min(3, Math.ceil(gridUnit / 10 - 0.05)));
}

// <folder>/<scale>x/<name>.png
function url(folder, name, gridUnit) {
    var f = String(folder);
    if (f !== "" && f.charAt(f.length - 1) !== "/")
        f += "/";
    return f + scale(gridUnit) + "x/" + name + ".png";
}
