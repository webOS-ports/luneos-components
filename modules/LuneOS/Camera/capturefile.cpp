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

#include "capturefile.h"

#include <QFile>
#include <QFileInfo>

#include <cerrno>
#include <fcntl.h>
#include <unistd.h>

/* How many names after the one asked for are tried. */
static const int kMaxSuffix = 99;

static QString candidate(const QString &path, int n)
{
    if (n == 0)
        return path;
    const QFileInfo info(path);
    const QString suffix = info.completeSuffix();
    const QString base = info.path() + QLatin1Char('/') + info.baseName() + QLatin1Char('-') + QString::number(n);
    return suffix.isEmpty() ? base : base + QLatin1Char('.') + suffix;
}

QString writeNewCaptureFile(const QString &path, const QByteArray &data)
{
    if (path.isEmpty())
        return QString();

    for (int n = 0; n <= kMaxSuffix; n++) {
        QString name = candidate(path, n);
        const QByteArray encoded = QFile::encodeName(name);
        const int fd = ::open(encoded.constData(),
                              O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0644);
        if (fd < 0) {
            if (errno == EEXIST)
                continue;
            return QString();
        }

        QFile file;
        if (!file.open(fd, QIODevice::WriteOnly, QFileDevice::AutoCloseHandle)) {
            ::close(fd);
            ::unlink(encoded.constData());
            return QString();
        }
        const bool written = file.write(data) == data.size() && file.flush();
        file.close();
        if (!written || file.error() != QFileDevice::NoError) {
            ::unlink(encoded.constData());
            return QString();
        }
        return name;
    }
    return QString();
}
