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

/*
 * LuneOS.Camera - the camera of a Halium device, for any QML application.
 *
 * On these devices the camera is only reachable through gst-droid's
 * droidcamsrc, and QtMultimedia cannot find it on its own: it enumerates V4L2,
 * where the camera does not appear. A QML Camera therefore binds to no device
 * and shows nothing at all - no error, just a blank preview.
 *
 * DroidCameraFactory builds a droidcamsrc source and hands it to QML to assign
 * to CaptureSession.nativeVideoSource. It began life inside the Camera app;
 * it lives here because a camera preview is not camera-app-specific - a QR
 * scanner wants exactly the same thing.
 */

#include <QtQml/QQmlExtensionPlugin>
#include <QtQml/QQmlEngine>
#include <QtQml/qqml.h>

#include <QFile>

#include "droidcamerafactory.h"

static QObject *droidCameraFactorySingleton(QQmlEngine *engine,
                                            QJSEngine *scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);

    return new DroidCameraFactory();
}

class LuneOSCameraPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        Q_ASSERT(uri == QLatin1String("LuneOS.Camera"));

        /*
         * The cameras on Halium devices are only reachable through gst-droid,
         * so QtMultimedia must use its GStreamer backend rather than the
         * ffmpeg default. This runs at import time, before the first
         * QtMultimedia object is instantiated and the backend choice is
         * locked in - which is the whole reason it belongs in the plugin
         * rather than in the application.
         */
        if (!qEnvironmentVariableIsSet("QT_MEDIA_BACKEND")
                && QFile::exists(QStringLiteral("/usr/lib/gstreamer-1.0/libgstdroid.so")))
            qputenv("QT_MEDIA_BACKEND", "gstreamer");

        // @uri LuneOS.Camera
        qmlRegisterSingletonType<DroidCameraFactory>(uri, 1, 0,
                        "DroidCameraFactory", droidCameraFactorySingleton);
    }
};

#include "plugin.moc"
