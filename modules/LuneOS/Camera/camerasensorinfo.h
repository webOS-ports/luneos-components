/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef CAMERASENSORINFO_H
#define CAMERASENSORINFO_H

#include <QObject>
#include <QString>

/*
 * How a camera sensor is physically mounted, read from the device tree the
 * same way libcamera does. Every camera-using app needs this to show an
 * upright preview, and it is a property of the board, not of any one app - so
 * it belongs here rather than hardcoded per app and per form factor.
 *
 * The kernel device tree gives each sensor node a "rotation" property (degrees
 * the sensor is turned relative to the panel's native orientation) and an
 * "orientation" property (0 front, 1 back, 2 external). libcamera reads both,
 * but Qt's multimedia backends do not carry the rotation through to
 * QCameraDevice, so a preview comes out turned by the mounting angle. This
 * exposes the raw device-tree values keyed by the libcamera camera id (which
 * is the sensor's device-tree path, e.g. "/base/i2c@fe5b0000/camera@36"), so
 * an app can rotate the viewfinder by exactly what the board declares.
 */
class CameraSensorInfo : public QObject
{
    Q_OBJECT

public:
    explicit CameraSensorInfo(QObject *parent = nullptr);

    /*
     * Mounting rotation in degrees (0/90/180/270) from the sensor's device-tree
     * "rotation" property, or -1 when the board does not declare one (then the
     * caller must fall back to a measured value). cameraId is the libcamera
     * camera id or its device-tree path; a leading "/base" alias is accepted.
     */
    Q_INVOKABLE int rotation(const QString &cameraId) const;

    /* Device-tree "orientation": 0 front, 1 back, 2 external; -1 if absent. */
    Q_INVOKABLE int orientation(const QString &cameraId) const;

private:
    int readDtU32(const QString &cameraId, const char *property) const;
};

#endif // CAMERASENSORINFO_H
