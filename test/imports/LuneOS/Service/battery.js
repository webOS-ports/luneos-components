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
 * A stand-in for batteryd (com.webos.service.battery).
 *
 * One pack, discharging, on no charger - which is what a laptop running the
 * mock is closest to. Deliberately no "batteries" array: the real service
 * only sends one where the device genuinely has more than one pack, so a
 * stub that always sent one would show a per-battery group that no ordinary
 * device ever shows.
 */
var percent = 68;
var charging = false;

/* Assigning a top level var of a .pragma library from QML is not reliable,
 * so every write from the mock goes through a function here. */
function setCharging(on) {
    charging = on;
}

function setPercent(value) {
    percent = value;
}

function batteryStatusPayload() {
    return {
        "returnValue": true,
        "percent": percent,
        "percent_ui": percent,
        "temperature_C": 29,
        "current_mA": charging ? 640 : -212,
        "voltage_mV": 3843,
        "capacity_mAh": 2842.0
    };
}

function chargerStatusPayload() {
    return {
        "returnValue": true,
        "DockConnected": false,
        "DockPower": false,
        // batteryd writes the string "NULL" rather than leaving it out when
        // there is no dock to name.
        "DockSerialNo": "NULL",
        "USBConnected": charging,
        "USBName": charging ? "wall" : "none",
        "Charging": charging
    };
}
