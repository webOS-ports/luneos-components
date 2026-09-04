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

/* Ask the GStreamer registry rather than probing a fixed path. gst-droid is
 * not always in the directory GStreamer scans by default: LuneOS installs it
 * in ${libdir}/gstreamer-1.0-gated and gst-droid-gate.service adds that to
 * GST_PLUGIN_PATH once the Android media services answer, so a hardcoded
 * ${libdir}/gstreamer-1.0 probe reports "not installed" on exactly the
 * devices where it is installed and working. */
/* The PulseAudio source to record from, resolved at run time.
 *
 * It cannot be hardcoded: the physical name differs per device
 * (source.primary_input on some, source.droid on others). Nor can it be left
 * unset, and nor can the LuneOS virtual source "record" be used - both end up
 * on a null source. module-palm-policy rewrites a capture stream that names
 * no device to the "record" virtual source, and that source only carries
 * anything once audiod has bound it to a physical input with
 * set_source_inputdevice(); until then it is module-null-source, i.e.
 * silence. Naming a physical source instead takes the policy module's
 * "physical device" path, which leaves the stream where we put it.
 *
 * The pulse device provider marks PulseAudio's default source with
 * is-default, and building an element from the GstDevice yields a pulsesrc
 * with its device property already filled in, so ask GStreamer rather than
 * guessing. */
static QByteArray recordingAudioSource()
{
    GstDeviceMonitor *monitor = gst_device_monitor_new();
    gst_device_monitor_add_filter(monitor, "Audio/Source", nullptr);

    if (!gst_device_monitor_start(monitor)) {
        gst_object_unref(monitor);
        return QByteArray();
    }

    QByteArray name;

    /* The pulse device provider enumerates over its own PulseAudio
     * connection, so the list is not populated by the time start() returns -
     * asking once yields nothing. Give it a moment to answer. */
    GList *devices = nullptr;
    for (int attempt = 0; attempt < 40 && !devices; attempt++) {
        devices = gst_device_monitor_get_devices(monitor);
        if (!devices)
            g_usleep(50 * 1000);
    }

    /* Prefer the source PulseAudio calls default, but do not depend on it:
     * is-default reflects a server query that is briefly unset while the
     * server is settling, and a recording started in that window would
     * otherwise fall back to silent video for no good reason. Any other
     * real pulse source is a better answer than none. The virtual sources
     * from webos-virtual-devices.pa are device.class=abstract and the ALSA
     * provider's nodes are not pulsesrc, so requiring class=sound from a
     * pulsesrc device excludes both. */
    QByteArray fallback;

    for (GList *l = devices; l && name.isEmpty(); l = l->next) {
        GstDevice *device = GST_DEVICE(l->data);

        GstStructure *props = gst_device_get_properties(device);
        if (!props)
            continue;

        gboolean isDefault = FALSE;
        gst_structure_get_boolean(props, "is-default", &isDefault);
        const gchar *deviceClass = gst_structure_get_string(props, "device.class");
        const bool soundSource = deviceClass && !g_strcmp0(deviceClass, "sound");
        gst_structure_free(props);

        if (!soundSource)
            continue;

        GstElement *element = gst_device_create_element(device, nullptr);
        if (!element)
            continue;

        GstElementFactory *factory = gst_element_get_factory(element);
        const bool isPulse =
            factory && !g_strcmp0(GST_OBJECT_NAME(factory), "pulsesrc");

        gchar *deviceName = nullptr;
        if (isPulse)
            g_object_get(element, "device", &deviceName, nullptr);

        if (deviceName) {
            if (isDefault)
                name = QByteArray(deviceName);
            else if (fallback.isEmpty())
                fallback = QByteArray(deviceName);
            g_free(deviceName);
        }
        gst_object_unref(element);
    }

    if (name.isEmpty())
        name = fallback;

    g_list_free_full(devices, gst_object_unref);
    gst_device_monitor_stop(monitor);
    gst_object_unref(monitor);

    if (name.isEmpty())
        qWarning() << "DroidCameraFactory: no default audio source for recording";

    return name;
}

/* Whether an audio source usable for recording can actually be opened.
 * Parsing the description only proves the syntax: pulsesrc resolves its
 * device on the way to PLAYING, so a missing or unusable source surfaces
 * as a bus error long after gst_parse_bin_from_description() succeeded -
 * leaving a recording running with a dead audio branch and a zero-byte
 * file. Probe it up front so the video-only fallback can be taken.
 *
 * It has to be driven all the way to PLAYING: pulsesrc only connects its
 * stream there (the "No such entity" failure comes out of
 * gst_pulsesrc_prepare), and being a live source it answers PAUSED with
 * NO_PREROLL rather than SUCCESS, which is not a failure. */
static bool audioSourceUsable(const char *device)
{
    gchar *desc = g_strdup_printf("pulsesrc device=%s ! fakesink sync=false", device);
    GError *error = nullptr;
    GstElement *probe = gst_parse_launch(desc, &error);
    g_free(desc);
    g_clear_error(&error);
    if (!probe)
        return false;

    bool ok = gst_element_set_state(probe, GST_STATE_PLAYING) != GST_STATE_CHANGE_FAILURE;

    if (ok) {
        const GstStateChangeReturn ret =
            gst_element_get_state(probe, nullptr, nullptr, 2 * GST_SECOND);
        ok = ret == GST_STATE_CHANGE_SUCCESS || ret == GST_STATE_CHANGE_NO_PREROLL;
    }

    if (ok) {
        GstBus *bus = gst_element_get_bus(probe);
        GstMessage *msg =
            gst_bus_timed_pop_filtered(bus, GST_SECOND, GST_MESSAGE_ERROR);
        if (msg) {
            ok = false;
            gst_message_unref(msg);
        }
        gst_object_unref(bus);
    }

    gst_element_set_state(probe, GST_STATE_NULL);
    gst_object_unref(probe);

    if (!ok)
        qWarning() << "DroidCameraFactory: audio source" << device
                   << "unusable, recording video only";
    return ok;
}

bool DroidCameraFactory::droidPluginAvailable()
{
    static const bool available = [] {
        gst_init(nullptr, nullptr);

        GstElementFactory *factory = gst_element_factory_find("droidcamsrc");
        if (!factory)
            return false;

        gst_object_unref(factory);
        return true;
    }();

    return available;
}

DroidCameraFactory::DroidCameraFactory(QObject *parent)
    : QObject(parent)
{
}

bool DroidCameraFactory::available() const
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    return droidPluginAvailable();
#else
    return false;
#endif
}

QObject *DroidCameraFactory::createVideoSource(int cameraDevice)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    if (!available())
        return nullptr;

    // A camera switch tears the old source (and any recording branch in
    // it) down wholesale; just drop our bookkeeping.
    if (m_recBin) {
        if (m_recTeePad)
            gst_object_unref(static_cast<GstPad *>(m_recTeePad));
        m_recBin = nullptr;
        m_recTeePad = nullptr;
        m_pendingVideoPath.clear();
        emit recordingChanged();
    }

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
    const QString desc = QStringLiteral(
        "droidcamsrc name=droidcam camera-device=%1 "
        "droidcam.imgsrc ! appsink name=droidimgsink emit-signals=true "
        "async=false sync=false "
        "droidcam.vidsrc ! fakesink name=vidsink async=false "
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

bool DroidCameraFactory::recording() const
{
    return m_recBin != nullptr;
}

bool DroidCameraFactory::startRecording(const QString &filePath)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
    if (!source || !source->gstElement() || m_recBin) {
        emit videoCaptureError(QStringLiteral("cannot start recording"));
        return false;
    }

    GstElement *bin = source->gstElement();

    QDir().mkpath(QFileInfo(filePath).absolutePath());

    // Preferred: hardware H264 through droidcamsrc's recorder mode. The
    // DroidMediaRecorder attaches the encoder to the camera session inside
    // the Android layer and vidsrc emits encoded frames, independent of
    // the raw viewfinder (needs the gst-droid raw-preview-recorder patch).
    if (startHwRecording(bin, filePath))
        return true;

    GstElement *tee = gst_bin_get_by_name(GST_BIN(bin), "vftee");
    if (!tee) {
        emit videoCaptureError(QStringLiteral("viewfinder tee not found"));
        return false;
    }

    // MPEG-4 part 2 in software: the hardware droidvenc only accepts
    // droid-buffer memory from droidcamsrc's video mode, which conflicts
    // with the raw viewfinder Qt needs. Encode at quarter pixels to keep
    // the CPU load sane. AAC audio from PulseAudio when available.
    const QByteArray audioSource = recordingAudioSource();
    const QString avDesc = QStringLiteral(
        "queue name=recentry max-size-buffers=30 leaky=downstream ! "
        "videoconvert ! videoscale ! "
        "video/x-raw,format=I420,width=1344,height=672 ! "
        "avenc_mpeg4 bitrate=8000000 ! mp4mux name=recmux ! "
        "filesink name=recsink async=false location=\"%1\" "
        "pulsesrc device=%2 ! audioconvert ! "
        "avenc_aac ! queue ! recmux.")
        .arg(filePath, QString::fromLatin1(audioSource));
    const QString vDesc = QStringLiteral(
        "queue name=recentry max-size-buffers=30 leaky=downstream ! "
        "videoconvert ! videoscale ! "
        "video/x-raw,format=I420,width=1344,height=672 ! "
        "avenc_mpeg4 bitrate=8000000 ! mp4mux name=recmux ! "
        "filesink name=recsink async=false location=\"%1\"")
        .arg(filePath);

    GError *error = nullptr;
    // A/V first; falls back to video-only when the audio chain cannot be
    // used (e.g. no droid mic source on this device - it needs the
    // 16-bit input override in /etc/pulse/droid-audio, see the recipe).
    GstElement *rec = nullptr;
    if (!audioSource.isEmpty() && audioSourceUsable(audioSource.constData()))
        rec = gst_parse_bin_from_description(
            avDesc.toUtf8().constData(), TRUE, &error);
    if (!rec) {
        g_clear_error(&error);
        rec = gst_parse_bin_from_description(vDesc.toUtf8().constData(),
                                             TRUE, &error);
    }
    if (!rec) {
        qWarning() << "DroidCameraFactory: recording bin failed:"
                   << (error ? error->message : "unknown");
        g_clear_error(&error);
        gst_object_unref(tee);
        emit videoCaptureError(QStringLiteral("cannot build recorder"));
        return false;
    }
    gst_element_set_name(rec, "recbin");

    gst_bin_add(GST_BIN(bin), rec);
    if (!gst_element_sync_state_with_parent(rec)) {
        gst_bin_remove(GST_BIN(bin), rec);
        gst_object_unref(tee);
        emit videoCaptureError(QStringLiteral("cannot start recorder"));
        return false;
    }

    GstPad *teepad = gst_element_request_pad_simple(tee, "src_%u");
    GstPad *sinkpad = gst_element_get_static_pad(rec, "sink");
    const bool linked =
        teepad && sinkpad && gst_pad_link(teepad, sinkpad) == GST_PAD_LINK_OK;
    if (sinkpad)
        gst_object_unref(sinkpad);
    gst_object_unref(tee);
    if (!linked) {
        gst_element_set_state(rec, GST_STATE_NULL);
        gst_bin_remove(GST_BIN(bin), rec);
        emit videoCaptureError(QStringLiteral("cannot link recorder"));
        return false;
    }

    m_recBin = rec;
    m_recTeePad = teepad;
    m_pendingVideoPath = filePath;
    qInfo() << "DroidCameraFactory: recording to" << filePath;
    emit recordingChanged();
    return true;
#else
    Q_UNUSED(filePath);
    return false;
#endif
}

void DroidCameraFactory::stopRecording()
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    if (m_hwRecording) {
        auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
        if (source && source->gstElement()) {
            GstElement *cam =
                gst_bin_get_by_name(GST_BIN(source->gstElement()), "droidcam");
            if (cam) {
                // droidcamsrc stops the recorder and pushes EOS through
                // vidsrc; the filesink probe fires finishHwRecording().
                g_signal_emit_by_name(cam, "stop-capture");
                gst_object_unref(cam);
            }
        }
        return;
    }

    if (!m_recBin || !m_recTeePad)
        return;

    auto *teepad = static_cast<GstPad *>(m_recTeePad);

    // Block the tee branch, unlink it, then run EOS through the encoder so
    // mp4mux writes its moov atom before the branch is torn down.
    gst_pad_add_probe(teepad, GST_PAD_PROBE_TYPE_IDLE,
        [](GstPad *pad, GstPadProbeInfo *, gpointer user) -> GstPadProbeReturn {
            auto *self = static_cast<DroidCameraFactory *>(user);
            auto *rec = static_cast<GstElement *>(self->m_recBin);

            GstPad *sinkpad = gst_element_get_static_pad(rec, "sink");
            gst_pad_unlink(pad, sinkpad);

            // EOS into the video branch; the audio source (if any) gets its
            // own EOS so both tracks finalize.
            GstElement *audiosrc =
                gst_bin_get_by_name(GST_BIN(rec), "pulsesrc0");
            if (audiosrc) {
                gst_element_send_event(audiosrc, gst_event_new_eos());
                gst_object_unref(audiosrc);
            }
            gst_pad_send_event(sinkpad, gst_event_new_eos());
            gst_object_unref(sinkpad);

            // Watch for EOS reaching the file sink.
            GstElement *filesink = gst_bin_get_by_name(GST_BIN(rec), "recsink");
            GstPad *fspad = gst_element_get_static_pad(filesink, "sink");
            gst_pad_add_probe(fspad,
                static_cast<GstPadProbeType>(GST_PAD_PROBE_TYPE_EVENT_DOWNSTREAM),
                [](GstPad *, GstPadProbeInfo *info, gpointer u) -> GstPadProbeReturn {
                    if (GST_EVENT_TYPE(GST_PAD_PROBE_INFO_EVENT(info)) !=
                        GST_EVENT_EOS)
                        return GST_PAD_PROBE_OK;
                    auto *fself = static_cast<DroidCameraFactory *>(u);
                    QMetaObject::invokeMethod(fself, [fself] {
                        fself->finishRecording();
                    }, Qt::QueuedConnection);
                    return GST_PAD_PROBE_REMOVE;
                }, self, nullptr);
            gst_object_unref(fspad);
            gst_object_unref(filesink);
            return GST_PAD_PROBE_REMOVE;
        }, this, nullptr);
#endif
}

void DroidCameraFactory::finishRecording()
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
    auto *rec = static_cast<GstElement *>(m_recBin);
    auto *teepad = static_cast<GstPad *>(m_recTeePad);
    if (!rec)
        return;

    gst_element_set_state(rec, GST_STATE_NULL);
    if (source && source->gstElement()) {
        GstElement *bin = source->gstElement();
        gst_bin_remove(GST_BIN(bin), rec);
        GstElement *tee = gst_bin_get_by_name(GST_BIN(bin), "vftee");
        if (tee) {
            gst_element_release_request_pad(tee, teepad);
            gst_object_unref(tee);
        }
    }
    gst_object_unref(teepad);

    const QString path = m_pendingVideoPath;
    m_pendingVideoPath.clear();
    m_recBin = nullptr;
    m_recTeePad = nullptr;
    emit recordingChanged();
    qInfo() << "DroidCameraFactory: saved recording to" << path;
    emit videoSaved(path);
#endif
}

bool DroidCameraFactory::startHwRecording(GstElement *bin,
                                          const QString &filePath)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    GstElement *cam = gst_bin_get_by_name(GST_BIN(bin), "droidcam");
    GstElement *vidsink = gst_bin_get_by_name(GST_BIN(bin), "vidsink");
    if (!cam || !vidsink) {
        if (cam) gst_object_unref(cam);
        if (vidsink) gst_object_unref(vidsink);
        return false;
    }

    const QByteArray audioSource = recordingAudioSource();
    const QString avDesc = QStringLiteral(
        "h264parse ! mp4mux name=recmux ! "
        "filesink name=recsink async=false location=\"%1\" "
        "pulsesrc device=%2 ! audioconvert ! "
        "avenc_aac ! queue ! recmux.")
        .arg(filePath, QString::fromLatin1(audioSource));
    const QString vDesc = QStringLiteral(
        "h264parse ! mp4mux name=recmux ! "
        "filesink name=recsink async=false location=\"%1\"").arg(filePath);

    GError *error = nullptr;
    GstElement *rec = nullptr;
    if (!audioSource.isEmpty() && audioSourceUsable(audioSource.constData()))
        rec = gst_parse_bin_from_description(
            avDesc.toUtf8().constData(), TRUE, &error);
    if (!rec) {
        g_clear_error(&error);
        rec = gst_parse_bin_from_description(vDesc.toUtf8().constData(),
                                             TRUE, &error);
    }
    if (!rec) {
        g_clear_error(&error);
        gst_object_unref(cam);
        gst_object_unref(vidsink);
        return false;
    }
    gst_element_set_name(rec, "hwrecbin");

    // vidsrc is quiescent outside recording, so relinking it is safe.
    GstPad *vidsrcpad = gst_element_get_static_pad(cam, "vidsrc");
    GstPad *oldsink = gst_element_get_static_pad(vidsink, "sink");
    gst_pad_unlink(vidsrcpad, oldsink);
    gst_object_unref(oldsink);

    gst_bin_add(GST_BIN(bin), rec);
    gst_element_sync_state_with_parent(rec);
    GstPad *recsink = gst_element_get_static_pad(rec, "sink");
    const bool linked = gst_pad_link(vidsrcpad, recsink) == GST_PAD_LINK_OK;
    gst_object_unref(recsink);

    if (!linked) {
        gst_element_set_state(rec, GST_STATE_NULL);
        gst_bin_remove(GST_BIN(bin), rec);
        GstPad *os = gst_element_get_static_pad(vidsink, "sink");
        gst_pad_link(vidsrcpad, os);
        gst_object_unref(os);
        gst_object_unref(vidsrcpad);
        gst_object_unref(cam);
        gst_object_unref(vidsink);
        return false;
    }
    gst_object_unref(vidsrcpad);

    // Video mode renegotiates vidsrc against h264parse, selecting the
    // hardware encoder; then start-capture begins the recording.
    g_object_set(cam, "mode", 2, nullptr);

    GstElement *filesink = gst_bin_get_by_name(GST_BIN(rec), "recsink");
    GstPad *fspad = gst_element_get_static_pad(filesink, "sink");
    gst_pad_add_probe(fspad,
        static_cast<GstPadProbeType>(GST_PAD_PROBE_TYPE_EVENT_DOWNSTREAM),
        [](GstPad *, GstPadProbeInfo *info, gpointer u) -> GstPadProbeReturn {
            if (GST_EVENT_TYPE(GST_PAD_PROBE_INFO_EVENT(info)) != GST_EVENT_EOS)
                return GST_PAD_PROBE_OK;
            auto *self = static_cast<DroidCameraFactory *>(u);
            QMetaObject::invokeMethod(self, [self] {
                self->finishHwRecording();
            }, Qt::QueuedConnection);
            return GST_PAD_PROBE_REMOVE;
        }, this, nullptr);
    gst_object_unref(fspad);
    gst_object_unref(filesink);

    g_signal_emit_by_name(cam, "start-capture");
    gst_object_unref(cam);
    gst_object_unref(vidsink);

    m_recBin = rec;
    m_hwRecording = true;
    m_pendingVideoPath = filePath;
    qInfo() << "DroidCameraFactory: HW recording to" << filePath;
    emit recordingChanged();
    return true;
#else
    Q_UNUSED(bin); Q_UNUSED(filePath);
    return false;
#endif
}

void DroidCameraFactory::finishHwRecording()
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
    auto *rec = static_cast<GstElement *>(m_recBin);
    if (!rec)
        return;

    gst_element_set_state(rec, GST_STATE_NULL);
    if (source && source->gstElement()) {
        GstElement *bin = source->gstElement();
        GstElement *cam = gst_bin_get_by_name(GST_BIN(bin), "droidcam");
        GstElement *vidsink = gst_bin_get_by_name(GST_BIN(bin), "vidsink");
        gst_bin_remove(GST_BIN(bin), rec);
        if (cam && vidsink) {
            GstPad *vidsrcpad = gst_element_get_static_pad(cam, "vidsrc");
            GstPad *os = gst_element_get_static_pad(vidsink, "sink");
            gst_pad_link(vidsrcpad, os);
            gst_object_unref(os);
            gst_object_unref(vidsrcpad);
            // back to image mode so stills work again
            g_object_set(cam, "mode", 1, nullptr);
        }
        if (cam) gst_object_unref(cam);
        if (vidsink) gst_object_unref(vidsink);
    }

    const QString path = m_pendingVideoPath;
    m_pendingVideoPath.clear();
    m_recBin = nullptr;
    m_hwRecording = false;
    emit recordingChanged();
    qInfo() << "DroidCameraFactory: saved HW recording to" << path;
    emit videoSaved(path);
#endif
}
