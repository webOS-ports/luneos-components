/*
 * Copyright (C) 2026 Herrie
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

#include "droidcamerafactory.h"

#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDebug>

#include <gst/gst.h>

#if __has_include(<QtMultimedia/spi/qgstreamervideosource.h>)
#include <QtMultimedia/spi/qgstreamervideosource.h>
#define HAVE_QGSTREAMER_VIDEO_SOURCE 1
#endif

static const QLatin1String cGstDroidPlugin("/usr/lib/gstreamer-1.0/libgstdroid.so");

DroidCameraFactory::DroidCameraFactory(QObject *parent)
    : QObject(parent)
{
}

bool DroidCameraFactory::available() const
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    return QFile::exists(cGstDroidPlugin);
#else
    return false;
#endif
}

QObject *DroidCameraFactory::createVideoSource(int cameraDevice)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    if (!available())
        return nullptr;

    // The capture session still points at the previous source here and
    // QMediaCaptureSession does not watch for its deletion, so a plain
    // delete would leave the session dispatching into freed memory when
    // the caller reassigns nativeVideoSource (it detaches the old source
    // first). deleteLater() runs after the caller's synchronous QML block
    // has completed that reassignment.
    if (m_videoSource)
        m_videoSource->deleteLater();
    m_videoSource = nullptr;

    // Park imgsrc and vidsrc on fakesinks so the viewfinder chain's tail is
    // the bin's only unlinked pad, which QGStreamerVideoSource ghosts as the
    // source pad. async=false because those pads only produce data during a
    // capture - a prerolling sink there would hold the whole pipeline in
    // PAUSED. The queue is load-bearing: droidcamsrc pushes sticky events
    // from its state-change context, and Qt activates the source from
    // inside a pad idle-probe on the ghost pad - an event push reaching
    // that pad from the state-change thread self-deadlocks. With the queue
    // in between, those pushes terminate at the queue sink and the queue's
    // own thread forwards them. Without a downstream that understands droid
    // queue buffers, droidcamsrc falls back to raw NV21 preview frames,
    // which the Qt GStreamer video sink accepts.
    // The NV21 capsfilter stays inside the bin so droidcamsrc's caps
    // negotiation - which runs while the ghost pad is still unlinked -
    // resolves to a real format and preview size before startPreview.
    // Started with the HAL's defaults instead, QCOM CamX rejects the
    // preview (error 0x1: opaque implementation-defined preview format).
    // The tee is not spare capacity for a second branch: without it the
    // frames the HAL delivers never reach the sink and the preview stays
    // black, with the camera running and nothing logged either side.
    const QString desc = QStringLiteral(
        "droidcamsrc name=droidcam camera-device=%1 "
        "droidcam.imgsrc ! appsink name=droidimgsink emit-signals=true "
        "async=false sync=false "
        "droidcam.vidsrc ! fakesink async=false "
        "droidcam.vfsrc ! capsfilter caps=video/x-raw,format=NV21 ! "
        "tee name=vftee ! queue ! videoconvert").arg(cameraDevice);

    qInfo() << "DroidCameraFactory: creating gst-droid video source:" << desc;
    auto *source = new QGStreamerVideoSource(desc, this);
    m_videoSource = source;

    // Full-resolution JPEGs from the HAL arrive on the imgsrc appsink when
    // a capture is triggered; the callback runs on a streaming thread.
    if (GstElement *bin = source->gstElement()) {
        GstElement *sink = gst_bin_get_by_name(GST_BIN(bin), "droidimgsink");
        if (sink) {
            g_signal_connect(sink, "new-sample",
                G_CALLBACK(+[](GstElement *appsink, gpointer user) -> GstFlowReturn {
                    auto *self = static_cast<DroidCameraFactory *>(user);
                    GstSample *sample = nullptr;
                    g_signal_emit_by_name(appsink, "pull-sample", &sample);
                    if (!sample)
                        return GST_FLOW_OK;
                    GstBuffer *buffer = gst_sample_get_buffer(sample);
                    QByteArray data;
                    GstMapInfo map;
                    if (buffer && gst_buffer_map(buffer, &map, GST_MAP_READ)) {
                        data = QByteArray(reinterpret_cast<const char *>(map.data),
                                          static_cast<int>(map.size));
                        gst_buffer_unmap(buffer, &map);
                    }
                    gst_sample_unref(sample);
                    if (!data.isEmpty())
                        QMetaObject::invokeMethod(self, [self, data] {
                            self->saveImage(data);
                        }, Qt::QueuedConnection);
                    return GST_FLOW_OK;
                }), this);
            gst_object_unref(sink);
        }
    }

    return m_videoSource;
#else
    Q_UNUSED(cameraDevice);
    return nullptr;
#endif
}

bool DroidCameraFactory::takePicture(const QString &filePath)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
    if (!source || !source->gstElement()) {
        emit imageCaptureError(QStringLiteral("no active droid camera"));
        return false;
    }

    GstElement *cam = gst_bin_get_by_name(GST_BIN(source->gstElement()),
                                          "droidcam");
    if (!cam) {
        emit imageCaptureError(QStringLiteral("droidcamsrc not found"));
        return false;
    }

    m_pendingImagePath = filePath;
    g_signal_emit_by_name(cam, "start-capture");
    gst_object_unref(cam);
    return true;
#else
    Q_UNUSED(filePath);
    return false;
#endif
}

void DroidCameraFactory::saveImage(const QByteArray &data)
{
    const QString path = m_pendingImagePath;
    m_pendingImagePath.clear();
    if (path.isEmpty())
        return;

    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly) || f.write(data) != data.size()) {
        emit imageCaptureError(QStringLiteral("cannot write %1").arg(path));
        return;
    }
    f.close();
    qInfo() << "DroidCameraFactory: saved capture to" << path;
    emit imageSaved(path);
}
