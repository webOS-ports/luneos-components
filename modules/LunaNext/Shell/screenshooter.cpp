/*
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
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

#include <QQuickWindow>
#include <QImage>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QDebug>

#include <algorithm>
#include <cerrno>
#include <climits>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include "screenshooter.h"

namespace luna
{

const char *const ScreenShooter::kDirectory = "/media/internal/screencaptures";

ScreenShooter::ScreenShooter(QQuickItem *parent) :
    QQuickItem(parent)
{
}

bool ScreenShooter::isPlainFileName(const QString &name)
{
    if (name.isEmpty() || name.startsWith(QLatin1Char('.')))
        return false;
    if (name.toUtf8().size() > NAME_MAX)
        return false;
    return std::none_of(name.cbegin(), name.cend(), [](QChar c) {
        const char16_t u = c.unicode();
        return u == u'/' || u == u'\\' || u < 0x20 || u == 0x7f;
    });
}

namespace
{

/* Opens dir as a directory without following a symlink, creating it if missing. */
int openDirectory(const QByteArray &dir)
{
    int dfd = ::open(dir.constData(), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (dfd < 0 && errno == ENOENT) {
        if (::mkdir(dir.constData(), 0755) != 0 && errno != EEXIST)
            return -1;
        dfd = ::open(dir.constData(), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    }
    return dfd;
}

/* Writes image into a new file name in dfd; false (and nothing left behind) on failure. */
bool writeNew(int dfd, const QString &name, const QImage &image, int *err)
{
    const QByteArray fileName = QFile::encodeName(name);
    const int fd = ::openat(dfd, fileName.constData(),
                            O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0644);
    if (fd < 0) {
        *err = errno;
        return false;
    }

    const QByteArray format = QFileInfo(name).suffix().toLatin1();
    bool saved = false;
    {
        QFile file;
        if (file.open(fd, QIODevice::WriteOnly, QFileDevice::AutoCloseHandle)) {
            saved = !format.isEmpty() && image.save(&file, format.constData());
            if (saved)
                saved = file.flush();
        } else {
            ::close(fd);
        }
    }
    if (!saved) {
        *err = 0;
        ::unlinkat(dfd, fileName.constData(), 0);
    }
    return saved;
}

} // namespace

QString ScreenShooter::save(const QImage &image, const QString &dir,
                            const QString &name, const QDateTime &now)
{
    if (!name.isEmpty() && !isPlainFileName(name)) {
        qWarning() << "Refusing to save a screenshot as" << name
                   << "- a plain file name is required";
        return QString();
    }

    const int dfd = openDirectory(QFile::encodeName(dir));
    if (dfd < 0) {
        qWarning() << "Cannot open the screenshot directory" << dir << ":" << qt_error_string(errno);
        return QString();
    }

    QString written;
    int err = 0;
    if (!name.isEmpty()) {
        if (writeNew(dfd, name, image, &err))
            written = name;
    } else {
        const QString stem = now.toString(QStringLiteral("yyyyMMddhhmmss"));
        for (int i = 0; i < 100 && written.isEmpty(); ++i) {
            const QString candidate = i == 0 ? stem + QStringLiteral(".png")
                                             : stem + QLatin1Char('-') + QString::number(i) + QStringLiteral(".png");
            if (writeNew(dfd, candidate, image, &err))
                written = candidate;
            else if (err != EEXIST)
                break;
        }
    }
    ::close(dfd);

    if (written.isEmpty()) {
        qWarning() << "Failed to save screenshot" << (err ? qt_error_string(err) : QString());
        return QString();
    }
    return dir + QLatin1Char('/') + written;
}

QString ScreenShooter::capture(const QString &path) const
{
    QQuickWindow *parentWindow = window();
    if (!parentWindow)
        return QString();

    const QImage image = parentWindow->grabWindow();
    const QString outputPath = save(image, QString::fromLatin1(kDirectory), path,
                                    QDateTime::currentDateTime());
    if (!outputPath.isEmpty())
        qDebug() << "Saved screenshot at" << outputPath;
    return outputPath;
}

} // namespace luna
