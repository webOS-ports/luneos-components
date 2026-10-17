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
 * What a list of files shows, the same in every app: a launch target as a
 * path, names without their folder or extension, sizes, days and times, the
 * order of names and matching a search. Plain functions over strings and
 * numbers, so an app's own tests can call them without the app around.
 *
 *   import LuneOS.Components 1.0
 *   ... FileLists.formatSize(file.size) ...
 *
 * No Intl in QML, so month names are English and days come first ("12 Oct"),
 * as the apps that showed dates already did.
 */

// A launch target as a local path: "/path", "file:///path" or
// "file://localhost/path", percent-encoded or not. "" for anything that is
// not a file on this device.
function localPath(target) {
    var t = String(target === undefined || target === null ? "" : target).trim();
    if (t.indexOf("file://") === 0) {
        t = t.substring(7);
        if (t.charAt(0) !== "/") {
            var slash = t.indexOf("/");
            if (slash < 0 || t.substring(0, slash) !== "localhost")
                return "";
            t = t.substring(slash);
        }
        try {
            t = decodeURIComponent(t);
        } catch (e) {
            return "";
        }
    }
    return t.charAt(0) === "/" ? t : "";
}

// The file: URL of a path, each part encoded, so "#" or "%" in a name
// survives.
function fileUrl(path) {
    return "file://" + String(path).split("/").map(function(part) {
        return encodeURIComponent(part);
    }).join("/");
}

// "Talk.MP3" for "/a/b/Talk.MP3".
function fileName(path) {
    var s = String(path === undefined || path === null ? "" : path);
    return s.substring(s.lastIndexOf("/") + 1);
}

// The folder a path is in: "/a/b" for "/a/b/c", "/" for "/c", "" for "c".
function folderOf(path) {
    var s = String(path === undefined || path === null ? "" : path);
    var slash = s.lastIndexOf("/");
    return slash > 0 ? s.substring(0, slash) : (slash === 0 ? "/" : "");
}

// "mp3" for "Talk.MP3": lower case, without the dot. "" when there is none,
// and for a hidden file's name alone (".profile").
function extensionOf(path) {
    var name = fileName(path);
    var dot = name.lastIndexOf(".");
    return dot > 0 ? name.substring(dot + 1).toLowerCase() : "";
}

// The name a list shows: the file name without its extension.
function displayName(path) {
    var name = fileName(path);
    var dot = name.lastIndexOf(".");
    return dot > 0 ? name.substring(0, dot) : name;
}

/*
 * Names in the order a reader expects: case aside, runs of digits by their
 * value ("Part 2" before "Part 10"). Where two runs have the same value the
 * shorter one comes first ("7" before "007"), so names that differ only in
 * their zeros still have one order instead of comparing equal.
 */
function naturalCompare(a, b) {
    var ax = String(a === undefined || a === null ? "" : a).toLowerCase().match(/\d+|\D+/g) || [];
    var bx = String(b === undefined || b === null ? "" : b).toLowerCase().match(/\d+|\D+/g) || [];
    for (var i = 0; i < Math.min(ax.length, bx.length); i++) {
        var x = ax[i], y = bx[i];
        if (x === y)
            continue;
        if (/^\d/.test(x) && /^\d/.test(y)) {
            var d = Number(x) - Number(y);
            if (d !== 0)
                return d < 0 ? -1 : 1;
            if (x.length !== y.length)
                return x.length < y.length ? -1 : 1;
            continue;
        }
        return x.localeCompare(y);
    }
    return ax.length - bx.length;
}

// Case and accents folded away, so "cafe" finds "Café".
function fold(s) {
    var t = String(s === undefined || s === null ? "" : s).toLowerCase();
    if (t.normalize)
        t = t.normalize("NFD").replace(/[̀-ͯ]/g, "");
    return t;
}

// Whether text holds every word of a search, case and accents aside. An
// empty search matches everything.
function matches(text, query) {
    var hay = fold(text);
    var words = fold(query).split(/\s+/);
    for (var i = 0; i < words.length; i++) {
        if (words[i] !== "" && hay.indexOf(words[i]) < 0)
            return false;
    }
    return true;
}

/*
 * A size as lists show it, in powers of 1024 like the computers the same
 * card is read on: "512 B", "1.5 KB", "12 MB", "1.2 GB". One decimal under
 * 10, where it tells 1.2 GB from 1.9 GB, and none where it is ".0". "" for a
 * size that is not known. A monitor that watches sizes change can ask for
 * the decimal up to a larger value (decimalsUnder, 100: "98.6 MB").
 */
function formatSize(bytes, decimalsUnder) {
    var b = Number(bytes);
    if (bytes === undefined || bytes === null || bytes === "" || !isFinite(b) || b < 0)
        return "";
    if (b < 1024)
        return Math.round(b) + " B";
    var units = ["KB", "MB", "GB", "TB"];
    var value = b / 1024;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
        value /= 1024;
        unit++;
    }
    var shown = value < (decimalsUnder > 0 ? decimalsUnder : 10) ? Math.round(value * 10) / 10 : Math.round(value);
    // 9.96 rounds up to 10.0: that is the next step's whole number
    if (shown >= 1024 && unit < units.length - 1) {
        shown = 1;
        unit++;
    }
    return shown + " " + units[unit];
}

function pad2(n) {
    return n < 10 ? "0" + n : String(n);
}

// A length or position in milliseconds as a clock: "0:07", "12:34",
// "1:02:03"; with hours, "0:12:34", so a column of them lines up.
function formatClock(ms, hours) {
    var total = Math.floor((isFinite(ms) && ms > 0 ? ms : 0) / 1000);
    var h = Math.floor(total / 3600);
    var m = Math.floor((total % 3600) / 60);
    var s = total % 60;
    if (h > 0 || hours)
        return h + ":" + pad2(m) + ":" + pad2(s);
    return m + ":" + pad2(s);
}

// The time of day: "06:30", or "6:30 AM" when use24h is false.
function formatTime(when, use24h) {
    var d = when instanceof Date ? when : new Date(when);
    if (isNaN(d.getTime()))
        return "";
    if (use24h === false) {
        var h = d.getHours() % 12;
        return (h === 0 ? 12 : h) + ":" + pad2(d.getMinutes()) + (d.getHours() < 12 ? " AM" : " PM");
    }
    return pad2(d.getHours()) + ":" + pad2(d.getMinutes());
}

var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

// Days between when's day and now's, by the calendar (0 today, 1 yesterday).
function daysAgo(when, now) {
    var d = when instanceof Date ? when : new Date(when);
    var n = now instanceof Date ? now : new Date(now === undefined ? Date.now() : now);
    var day = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
    var today = new Date(n.getFullYear(), n.getMonth(), n.getDate()).getTime();
    return Math.round((today - day) / 86400000);
}

/*
 * The day a file is from: "Today", "Yesterday", "12 Oct", and "12 Oct 2025"
 * when it is not this year's. when and now are Dates or milliseconds; now is
 * there for the tests. "" for no date (0 or not a date).
 */
function formatDay(when, now) {
    var d = when instanceof Date ? when : new Date(when || NaN);
    if (isNaN(d.getTime()))
        return "";
    var n = now instanceof Date ? now : new Date(now === undefined ? Date.now() : now);
    var ago = daysAgo(d, n);
    if (ago === 0)
        return "Today";
    if (ago === 1)
        return "Yesterday";
    var text = d.getDate() + " " + monthNames[d.getMonth()];
    return d.getFullYear() === n.getFullYear() ? text : text + " " + d.getFullYear();
}

// As formatDay, with the time for today and yesterday: "Today 06:30",
// "Yesterday 6:02 PM", "12 Oct".
function formatWhen(when, now, use24h) {
    var day = formatDay(when, now);
    if (day === "Today" || day === "Yesterday")
        return day + " " + formatTime(when, use24h);
    return day;
}
