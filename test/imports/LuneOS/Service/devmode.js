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
 * A stand-in for org.webosports.service.devmode.
 *
 * Both flags are the strings "enabled" and "disabled", not booleans, and
 * turning developer mode off stops adb with it - the real service does that,
 * so this does too, or the panel cannot be seen behaving correctly.
 */
var status = "disabled";
var usbDebugging = "disabled";

function statusPayload() {
    return {
        "returnValue": true,
        "status": status,
        "usbDebugging": usbDebugging
    };
}

function setStatus(args) {
    if (args.status !== undefined) {
        status = args.status;
        if (status === "disabled")
            usbDebugging = "disabled";
    }
    if (args.usbDebugging !== undefined)
        usbDebugging = args.usbDebugging;

    return { "returnValue": true, "errorText": "", "errorCode": 0 };
}
