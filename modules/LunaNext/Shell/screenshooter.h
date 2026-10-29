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

#ifndef SCREENSHOOTER_H_
#define SCREENSHOOTER_H_

#include <QQuickItem>

class QDateTime;
class QImage;

namespace luna
{

class ScreenShooter : public QQuickItem
{
    Q_OBJECT

public:
    explicit ScreenShooter(QQuickItem *parent = 0);

    /* Where capture() writes. */
    static const char *const kDirectory;

    /*
     * True if name is a plain file name: not empty, at most NAME_MAX bytes
     * of UTF-8, no '/', '\\', NUL or control characters, and no leading '.'
     * (which also rules out "." and "..").
     */
    static bool isPlainFileName(const QString &name);

    /*
     * Writes image as dir/name, or as dir/<now as yyyyMMddhhmmss>.png when
     * name is empty, and returns the path written, or an empty string.
     *
     * dir must be a real directory, not a symlink; it is created (0755) if
     * missing. The file is created with O_EXCL | O_NOFOLLOW, so an existing
     * file or symlink is never written through or replaced: an explicit name
     * that exists fails, a generated name gets "-1", "-2", ... appended.
     */
    static QString save(const QImage &image, const QString &dir,
                        const QString &name, const QDateTime &now);

public slots:
    /*
     * Saves the window under kDirectory. path must be a plain file name
     * (see isPlainFileName()) or empty for a timestamped name; anything
     * else, such as an absolute path or one with "..", is refused.
     */
    QString capture(const QString &path) const;
};

} // namespace luna

#endif
