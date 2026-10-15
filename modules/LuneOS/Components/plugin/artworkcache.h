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

#ifndef ARTWORKCACHE_H_
#define ARTWORKCACHE_H_

#include <QImage>
#include <QSize>
#include <QString>

/*
 * An app's SVG artwork, drawn once at the size it is shown and kept as PNG.
 *
 * Artwork kept as SVG is sharp at whatever size a device's grid unit makes it,
 * but drawing SVG is slow on the older phones: a glossy button of a few dozen
 * gradients takes some 25 ms on a TouchPad, where the same picture as PNG loads
 * in about one. So each picture is drawn the first time it is asked for at a
 * size and saved under the cache directory, and from then on that PNG is
 * loaded. Each directory of artwork has its own folder there, so apps do not
 * share files; a file's name holds the picture's name, the size and a hash of
 * the SVG, so a new size or a changed picture is drawn afresh, and an older
 * version's files are removed when the new one is saved.
 *
 * Safe to use from several threads at once: every call works on its own
 * renderer and image, and files are written whole, then renamed into place.
 */
class ArtworkCache
{
public:
    explicit ArtworkCache(const QString &cacheDir);

    /// The SVG at "svgPath" (absolute) drawn at "size", or at its own size, or
    /// with the side left out (0) in its own proportions. A null image if
    /// there is no such SVG, it does not parse, or the size is unreasonable.
    QImage image(const QString &svgPath, const QSize &size, QSize *originalSize = nullptr) const;

    /// Where image() keeps "svgPath" at "size" (both sides given).
    QString cachePath(const QString &svgPath, const QSize &size) const;

    /// The SVG's path from an image://artwork id: a path or file: URL,
    /// percent-encoded (ArtworkImage.qml encodes it whole).
    static QString pathFromId(const QString &id);

private:
    QString m_cacheDir;
};

#endif
