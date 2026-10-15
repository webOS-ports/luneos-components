/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
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

#include <QtQml>
#include <QQuickImageProvider>
#include <QStandardPaths>

#include "artworkcache.h"
#include "plugin.h"

namespace {

/*
 * image://artwork/<SVG>: an app's SVG artwork at the size the Image asks for
 * with sourceSize, drawn once and then loaded as PNG; see ArtworkCache and
 * ArtworkImage.qml. The id is the SVG's absolute path or file: URL,
 * percent-encoded. Loaded off the GUI thread, so the window never waits on it.
 */
class ArtworkProvider : public QQuickImageProvider
{
public:
    explicit ArtworkProvider(const QString &cacheDir)
        : QQuickImageProvider(QQuickImageProvider::Image, QQuickImageProvider::ForceAsynchronousImageLoading)
        , m_cache(cacheDir)
    {
    }

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override
    {
        return m_cache.image(ArtworkCache::pathFromId(id), requestedSize, size);
    }

private:
    ArtworkCache m_cache;
};

} // namespace

Plugin::Plugin(QObject *parent) :
    QQmlExtensionPlugin(parent)
{
}

void Plugin::registerTypes(const char *uri)
{
    Q_UNUSED(uri);
}

void Plugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_UNUSED(uri);
    // One cache for every app, each app's artwork in a folder of its own.
    engine->addImageProvider(QStringLiteral("artwork"), new ArtworkProvider(
        QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + QStringLiteral("/luneos-components/artwork")));
}
