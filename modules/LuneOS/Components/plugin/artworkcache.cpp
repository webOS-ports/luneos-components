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

#include "artworkcache.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QPainter>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSvgRenderer>
#include <QUrl>

namespace {

/* What a picture is known by in the cache: the SVG's own name, with anything
 * but letters, digits, '-' and '_' replaced, so it is a plain file name. */
QString pictureName(const QFileInfo &svg)
{
    QString name = svg.completeBaseName();
    for (QChar &c : name) {
        const char l = c.toLatin1();
        if (!((l >= 'a' && l <= 'z') || (l >= 'A' && l <= 'Z') || (l >= '0' && l <= '9') || l == '-' || l == '_'))
            c = QLatin1Char('_');
    }
    return name.left(64);
}

QByteArray hash12(const QByteArray &data)
{
    return QCryptographicHash::hash(data, QCryptographicHash::Sha1).toHex().left(12);
}

QString fileName(const QString &name, const QSize &size, const QByteArray &hash)
{
    return QStringLiteral("%1-%2x%3-%4.png").arg(name).arg(size.width()).arg(size.height()).arg(QString::fromLatin1(hash));
}

/* The SVG, if "path" names one: absolute, ending in .svg, a readable file. */
bool readSvg(const QString &path, QFileInfo *info, QByteArray *svg)
{
    *info = QFileInfo(path);
    if (!info->isAbsolute() || info->suffix().compare(QLatin1String("svg"), Qt::CaseInsensitive) != 0 || !info->isFile())
        return false;
    QFile file(info->canonicalFilePath());
    if (!file.open(QIODevice::ReadOnly))
        return false;
    *svg = file.readAll();
    return true;
}

} // namespace

QString ArtworkCache::pathFromId(const QString &id)
{
    const QString decoded = QUrl::fromPercentEncoding(id.toUtf8());
    return decoded.startsWith(QLatin1String("file:")) ? QUrl(decoded).toLocalFile() : decoded;
}

ArtworkCache::ArtworkCache(const QString &cacheDir)
    : m_cacheDir(cacheDir)
{
}

QString ArtworkCache::cachePath(const QString &svgPath, const QSize &size) const
{
    QFileInfo info;
    QByteArray svg;
    if (!readSvg(svgPath, &info, &svg))
        return QString();
    const QString dir = m_cacheDir + QLatin1Char('/') + QString::fromLatin1(hash12(info.canonicalPath().toUtf8()));
    return dir + QLatin1Char('/') + fileName(pictureName(info), size, hash12(svg));
}

QImage ArtworkCache::image(const QString &svgPath, const QSize &size, QSize *originalSize) const
{
    QFileInfo info;
    QByteArray svg;
    if (!readSvg(svgPath, &info, &svg))
        return QImage();

    QSvgRenderer renderer;
    QSize want = size;
    if (want.width() <= 0 || want.height() <= 0) {
        // Not both given: the picture's own size, or its proportions for the
        // side left out (an Image that sets only sourceSize.width). Either needs
        // the SVG parsed.
        if (!renderer.load(svg))
            return QImage();
        const QSize own = renderer.defaultSize();
        if (own.isEmpty())
            return QImage();
        if (want.width() > 0)
            want.setHeight(qMax(1, qRound(qreal(want.width()) * own.height() / own.width())));
        else if (want.height() > 0)
            want.setWidth(qMax(1, qRound(qreal(want.height()) * own.width() / own.height())));
        else
            want = own;
    }
    if (originalSize)
        *originalSize = want;
    if (want.isEmpty() || want.width() > 4096 || want.height() > 4096)
        return QImage();

    const QString name = pictureName(info);
    const QByteArray hash = hash12(svg);
    const QString dir = m_cacheDir + QLatin1Char('/') + QString::fromLatin1(hash12(info.canonicalPath().toUtf8()));
    const QString path = dir + QLatin1Char('/') + fileName(name, want, hash);
    QImage cached(path);
    if (!cached.isNull() && cached.size() == want)
        return cached;

    if (!renderer.isValid() && !renderer.load(svg))
        return QImage();
    QImage image(want, QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::transparent);
    {
        QPainter painter(&image);
        painter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
        renderer.render(&painter);
    }

    // Kept for next time if the cache can be written; shown either way.
    if (QDir().mkpath(dir)) {
        QSaveFile out(path);
        if (out.open(QIODevice::WriteOnly) && image.save(&out, "PNG") && out.commit()) {
            // An older version of this picture is not needed any more. Matched
            // exactly: "flash-off" must not take "flash-off-pressed" with it.
            const QRegularExpression mine(QStringLiteral("^%1-\\d+x\\d+-([0-9a-f]{12})\\.png$")
                                              .arg(QRegularExpression::escape(name)));
            const QStringList files = QDir(dir).entryList({name + QStringLiteral("-*.png")}, QDir::Files);
            for (const QString &f : files) {
                const QRegularExpressionMatch m = mine.match(f);
                if (m.hasMatch() && m.capturedView(1) != QLatin1String(hash))
                    QFile::remove(dir + QLatin1Char('/') + f);
            }
        }
    }
    return image;
}
