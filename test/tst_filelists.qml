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
import QtTest
import LuneOS.Components 1.0

/*
 * FileLists, the helpers apps share for lists of files:
 *   qmltestrunner -import modules -import test/imports -input test/tst_filelists.qml
 */
TestCase {
    name: "FileLists"

    function test_localPath_data() {
        return [
            { tag: "plain path", target: "/media/internal/a.pdf", path: "/media/internal/a.pdf" },
            { tag: "file URL", target: "file:///media/internal/a.pdf", path: "/media/internal/a.pdf" },
            { tag: "localhost", target: "file://localhost/media/internal/a.pdf", path: "/media/internal/a.pdf" },
            { tag: "encoded", target: "file:///media/internal/My%20Book%23.pdf", path: "/media/internal/My Book#.pdf" },
            { tag: "spaces around", target: "  /a/b  ", path: "/a/b" },
            { tag: "other host", target: "file://server/a.pdf", path: "" },
            { tag: "web", target: "http://example.com/a.pdf", path: "" },
            { tag: "relative", target: "a.pdf", path: "" },
            { tag: "bad escape", target: "file:///a%zz.pdf", path: "" },
            { tag: "empty", target: "", path: "" },
            { tag: "undefined", target: undefined, path: "" },
            { tag: "null", target: null, path: "" }
        ];
    }
    function test_localPath(data) {
        compare(FileLists.localPath(data.target), data.path);
    }

    function test_fileUrl_roundTrips() {
        var path = "/media/internal/50% off #1 ?.mp4";
        var url = FileLists.fileUrl(path);
        compare(url, "file:///media/internal/50%25%20off%20%231%20%3F.mp4");
        compare(FileLists.localPath(url), path);
    }

    function test_names() {
        compare(FileLists.fileName("/a/b/Talk.MP3"), "Talk.MP3");
        compare(FileLists.fileName("Talk.MP3"), "Talk.MP3");
        compare(FileLists.fileName(undefined), "");
        compare(FileLists.folderOf("/a/b/c"), "/a/b");
        compare(FileLists.folderOf("/c"), "/");
        compare(FileLists.folderOf("c"), "");
        compare(FileLists.extensionOf("/a/Talk.MP3"), "mp3");
        compare(FileLists.extensionOf("/a/archive.tar.gz"), "gz");
        compare(FileLists.extensionOf("/a/.profile"), "");
        compare(FileLists.extensionOf("/a.b/noext"), "");
        compare(FileLists.displayName("/a/Manual.pdf"), "Manual");
        compare(FileLists.displayName("/a/movie.en.srt"), "movie.en");
        compare(FileLists.displayName("/a/.hidden"), ".hidden");
    }

    function test_naturalCompare() {
        var names = ["Part 10", "part 2", "Part 1", "Part 007", "Part 7", "Zebra", "apple", "Part 2b", ""];
        names.sort(FileLists.naturalCompare);
        compare(names, ["", "apple", "Part 1", "part 2", "Part 2b", "Part 7", "Part 007", "Part 10", "Zebra"]);
        compare(FileLists.naturalCompare("Same", "same"), 0);
        verify(FileLists.naturalCompare("7", "007") < 0);
        verify(FileLists.naturalCompare("007", "7") > 0);
        verify(FileLists.naturalCompare("a", undefined) > 0);
        // Too long for a double to tell apart: the shorter run, which is the
        // smaller number, still comes first
        verify(FileLists.naturalCompare("x 99999999999999999999", "x 100000000000000000001") < 0);
    }

    function test_matches() {
        verify(FileLists.matches("Café de Flore", "cafe"));
        verify(FileLists.matches("Café de Flore", "FLORE café"));
        verify(!FileLists.matches("Café de Flore", "cafe bar"));
        verify(FileLists.matches("anything", ""));
        verify(FileLists.matches("anything", "   "));
        verify(!FileLists.matches(undefined, "x"));
    }

    function test_formatSize_data() {
        return [
            { tag: "zero", bytes: 0, text: "0 B" },
            { tag: "bytes", bytes: 512, text: "512 B" },
            { tag: "1023", bytes: 1023, text: "1023 B" },
            { tag: "1 KB", bytes: 1024, text: "1 KB" },
            { tag: "1.5 KB", bytes: 1536, text: "1.5 KB" },
            { tag: "9.96 KB rounds to 10", bytes: 10199, text: "10 KB" },
            { tag: "12 MB", bytes: 12.4 * 1024 * 1024, text: "12 MB" },
            { tag: "1023.6 KB is 1 MB", bytes: 1023.6 * 1024, text: "1 MB" },
            { tag: "1.2 GB", bytes: 1.24 * 1024 * 1024 * 1024, text: "1.2 GB" },
            { tag: "2 GB no .0", bytes: 2 * 1024 * 1024 * 1024, text: "2 GB" },
            { tag: "TB", bytes: 3 * Math.pow(1024, 4), text: "3 TB" },
            { tag: "past TB", bytes: 5000 * Math.pow(1024, 4), text: "5000 TB" },
            { tag: "string number", bytes: "2048", text: "2 KB" },
            { tag: "unknown", bytes: undefined, text: "" },
            { tag: "null", bytes: null, text: "" },
            { tag: "negative", bytes: -1, text: "" },
            { tag: "not a number", bytes: "x", text: "" }
        ];
    }
    function test_formatSize(data) {
        compare(FileLists.formatSize(data.bytes), data.text);
    }

    function test_formatSize_decimals_further() {
        compare(FileLists.formatSize(98.6 * 1024 * 1024, 100), "98.6 MB");
        compare(FileLists.formatSize(98.6 * 1024 * 1024), "99 MB");
        compare(FileLists.formatSize(123.4 * 1024 * 1024, 100), "123 MB");
        compare(FileLists.formatSize(512, 100), "512 B");
    }

    function test_formatClock() {
        compare(FileLists.formatClock(7000), "0:07");
        compare(FileLists.formatClock(754000), "12:34");
        compare(FileLists.formatClock(3723000), "1:02:03");
        compare(FileLists.formatClock(754000, true), "0:12:34");
        compare(FileLists.formatClock(-5), "0:00");
        compare(FileLists.formatClock(NaN), "0:00");
        compare(FileLists.formatClock(1999), "0:01");
    }

    function test_formatTime() {
        var morning = new Date(2026, 9, 17, 6, 5);
        var evening = new Date(2026, 9, 17, 18, 2);
        compare(FileLists.formatTime(morning), "06:05");
        compare(FileLists.formatTime(morning, true), "06:05");
        compare(FileLists.formatTime(morning, false), "6:05 AM");
        compare(FileLists.formatTime(evening, false), "6:02 PM");
        compare(FileLists.formatTime(new Date(2026, 9, 17, 0, 30), false), "12:30 AM");
        compare(FileLists.formatTime(new Date(2026, 9, 17, 12, 30), false), "12:30 PM");
        compare(FileLists.formatTime(morning.getTime()), "06:05");
        compare(FileLists.formatTime("not a date"), "");
    }

    function test_formatDay() {
        var now = new Date(2026, 9, 17, 9, 0);
        compare(FileLists.formatDay(new Date(2026, 9, 17, 0, 1), now), "Today");
        compare(FileLists.formatDay(new Date(2026, 9, 16, 23, 59), now), "Yesterday");
        compare(FileLists.formatDay(new Date(2026, 9, 12), now), "12 Oct");
        compare(FileLists.formatDay(new Date(2025, 0, 3), now), "3 Jan 2025");
        compare(FileLists.formatDay(new Date(2026, 9, 12).getTime(), now.getTime()), "12 Oct");
        compare(FileLists.formatDay(0, now), "");
        compare(FileLists.formatDay(undefined, now), "");
        // Across the turn of the year and of daylight saving time
        compare(FileLists.formatDay(new Date(2025, 11, 31, 22), new Date(2026, 0, 1, 1)), "Yesterday");
        compare(FileLists.formatDay(new Date(2026, 2, 28, 12), new Date(2026, 2, 29, 12)), "Yesterday");
    }

    function test_formatWhen() {
        var now = new Date(2026, 9, 17, 9, 0);
        compare(FileLists.formatWhen(new Date(2026, 9, 17, 6, 30), now), "Today 06:30");
        compare(FileLists.formatWhen(new Date(2026, 9, 16, 18, 2), now, false), "Yesterday 6:02 PM");
        compare(FileLists.formatWhen(new Date(2026, 9, 12, 18, 2), now), "12 Oct");
        compare(FileLists.formatWhen(0, now), "");
    }
}
