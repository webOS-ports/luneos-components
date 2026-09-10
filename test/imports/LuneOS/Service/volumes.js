/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

.pragma library

/*
 * A stand-in for storaged's /volumes category.
 *
 * A phone-shaped device: the root filesystem, a separate /media/internal for
 * user data, and an SD card. Not encrypted, which is what every LuneOS device
 * is today - a mock that pretended otherwise would hide the state the
 * encryption panel exists to report.
 *
 * The root filesystem is nearly full on purpose. It is the one figure that
 * makes a storage page worth having, and a mock where everything sat at
 * thirty per cent would never show the warning colours.
 */
var volumes = [
    {
        "mountPoint": "/", "device": "/dev/mmcblk0p12", "fsType": "ext4",
        "readOnly": false,
        "sizeBytes": 3221225472, "freeBytes": 262144000, "availableBytes": 161061273,
        "encrypted": false
    },
    {
        "mountPoint": "/media/internal", "device": "/dev/mmcblk0p13",
        "fsType": "ext4", "readOnly": false,
        "sizeBytes": 25769803776, "freeBytes": 15032385536, "availableBytes": 13743895347,
        "encrypted": false
    },
    {
        "mountPoint": "/media/sdcard", "device": "/dev/mmcblk1p1",
        "fsType": "vfat", "readOnly": false,
        "sizeBytes": 31138512896, "freeBytes": 29669261312, "availableBytes": 29669261312,
        "encrypted": false
    }
];

function spaceInfoPayload() {
    return { "returnValue": true, "volumes": volumes };
}

/* The same list; the real service answers both from one walk of the mount
 * table and only leaves the encryption fields off getSpaceInfo. */
function encryptionStatusPayload() {
    return { "returnValue": true, "volumes": volumes };
}
