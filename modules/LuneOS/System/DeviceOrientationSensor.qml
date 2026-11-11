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

import QtSensors 5.11

/*
 * DeviceOrientation's accelerometer, in a file of its own so that only a
 * Loader fails where QtSensors is not installed, not every importer.
 *
 * The raw accelerometer rather than OrientationSensor: sensorfw's
 * orientation interpreter turns after 20-25 degrees of tilt, and less than
 * that when the phone is held leaning back. See OrientationFilter.js for
 * the rule used instead.
 */
Accelerometer {
    signal sampled(real x, real y, real z)

    active: true
    onReadingChanged: {
        if (reading)
            sampled(reading.x, reading.y, reading.z);
    }
}
