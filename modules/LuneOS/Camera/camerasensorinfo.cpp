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

#include "camerasensorinfo.h"

#include <QFile>
#include <QByteArray>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(lcSensorInfo, "luneos.camera.sensorinfo")

CameraSensorInfo::CameraSensorInfo(QObject *parent)
    : QObject(parent)
{
}

/*
 * Turn a libcamera camera id into the /proc/device-tree node that describes the
 * sensor, then read a 32-bit big-endian property from it. The id is the
 * sensor's device-tree path; the tree is rooted at "/base" (the SoC's soc@0
 * simple-bus alias) in the id but at "/proc/device-tree" on disk, so strip a
 * leading "/base". Returns the value, or -1 when the node or property is
 * missing (an older device tree that does not declare it).
 */
int CameraSensorInfo::readDtU32(const QString &cameraId, const char *property) const
{
    if (cameraId.isEmpty())
        return -1;

    QString node = cameraId;

    // The libcamera id may be the bare path or carry the "/base" root alias.
    if (node.startsWith(QLatin1String("/base/")))
        node = node.mid(QStringLiteral("/base").length());
    else if (node == QLatin1String("/base"))
        return -1;

    if (!node.startsWith(QLatin1Char('/')))
        node.prepend(QLatin1Char('/'));

    const QString path = QStringLiteral("/proc/device-tree") + node
                       + QLatin1Char('/') + QLatin1String(property);

    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        qCDebug(lcSensorInfo) << "no" << property << "at" << path;
        return -1;
    }

    const QByteArray data = f.read(4);
    if (data.size() != 4) {
        qCWarning(lcSensorInfo) << "short read of" << path;
        return -1;
    }

    // Device-tree cells are big-endian.
    const int value = (static_cast<quint8>(data[0]) << 24)
                    | (static_cast<quint8>(data[1]) << 16)
                    | (static_cast<quint8>(data[2]) << 8)
                    |  static_cast<quint8>(data[3]);

    qCDebug(lcSensorInfo) << property << "=" << value << "for" << cameraId
                          << "(" << path << ")";
    return value;
}

int CameraSensorInfo::rotation(const QString &cameraId) const
{
    return readDtU32(cameraId, "rotation");
}

int CameraSensorInfo::orientation(const QString &cameraId) const
{
    return readDtU32(cameraId, "orientation");
}
