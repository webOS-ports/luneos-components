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
#include "droidcamerabin.h"
#include "cameracontrols.h"

#include <QCoreApplication>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <QPointer>
#include <QTimer>

#include <cmath>
#include <thread>

#include <gst/gst.h>
#include <gst/interfaces/photography.h>

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
            g_usleep(50 * G_TIME_SPAN_MILLISECOND);
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

/* How long the vendor recorder gets to produce its first encoded frame
 * before the software encoder takes over. Long enough for a slow HAL to
 * spin up its encoder, short enough not to lose the shot. */
static const int kHwRecordingGraceMs = 2500;

bool DroidCameraFactory::droidPluginAvailable()
{
    static const bool found = [] {
        gst_init(nullptr, nullptr);

        GstElementFactory *factory = gst_element_factory_find("droidcamsrc");
        if (!factory)
            return false;

        gst_object_unref(factory);
        return true;
    }();

    return found;
}

/* How long a still waits for autofocus before it is taken regardless. Long
 * enough for a HAL's contrast sweep in poor light, short enough that a shutter
 * press never feels ignored. */
static const int kFocusBeforeCaptureMs = 2000;
/* How long a tap-to-focus may run before it is reported as failed: some HALs
 * never answer a focus request at all. */
static const int kFocusResultMs = 4000;
/* How long a HAL gets to hand over a still once the shutter is released. HDR
 * and night scene modes merge several frames, which takes seconds on older
 * phones. */
static const int kCaptureTimeoutMs = 15000;

DroidCameraFactory::DroidCameraFactory(QObject *parent)
    : QObject(parent)
{
    m_focusTimeout.setSingleShot(true);
    connect(&m_focusTimeout, &QTimer::timeout, this, [this] {
        if (m_focusStatus == FocusRunning)
            setFocusStatus(FocusFailed);
        if (m_captureAfterFocus)
            releaseShutter();
    });
}

DroidCameraFactory::~DroidCameraFactory()
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    /* The image sink's handler is the one that holds a plain pointer to the
     * factory (the camera's own handlers go through a QPointer); nothing may
     * call back into a factory that is gone. */
    auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
    if (source && source->gstElement()) {
        if (GstElement *sink = gst_bin_get_by_name(GST_BIN(source->gstElement()), "droidimgsink")) {
            g_signal_handlers_disconnect_by_data(sink, this);
            gst_object_unref(sink);
        }
    }
#endif
}

/* The camera count, taken from gst-droid rather than from droidmedia
 * directly, so that nothing here has to link the Android side.
 *
 * gst_droidcamsrc_class_init() installs the "camera-device" property only
 * when the HAL reports at least one camera, and gives it the range
 *
 *     0 .. droid_media_camera_get_number_of_cameras() - 1
 *
 * so the paramspec's maximum is the real count minus one, and the property's
 * absence means no cameras at all. Reading the class is enough - no element
 * is instantiated and no camera is opened, which matters because this HAL
 * serves one client at a time.
 */
int DroidCameraFactory::cameraCount() const
{
    static const int count = [] () -> int {
        if (!droidPluginAvailable())
            return 0;

        GstElementFactory *factory = gst_element_factory_find("droidcamsrc");
        if (!factory)
            return 0;

        /* find() hands back the registry entry without loading the plugin,
         * and an unloaded feature has no element GType yet - the class that
         * installs "camera-device" has not run. Load it first. */
        factory = GST_ELEMENT_FACTORY(
            gst_plugin_feature_load(GST_PLUGIN_FEATURE(factory)));
        if (!factory)
            return 0;

        GType type = gst_element_factory_get_element_type(factory);
        gst_object_unref(factory);
        if (type == G_TYPE_INVALID)
            return 0;

        gpointer klass = g_type_class_ref(type);
        if (!klass)
            return 0;

        GParamSpec *spec =
            g_object_class_find_property(G_OBJECT_CLASS(klass), "camera-device");
        /* Range-checked rather than cast blindly: if gst-droid ever respells
         * the property, a wrong cast here would read rubbish as a count. */
        const int n = (spec && G_IS_PARAM_SPEC_INT(spec))
                          ? G_PARAM_SPEC_INT(spec)->maximum + 1
                          : 0;
        g_type_class_unref(klass);

        return n;
    }();

    return count;
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

    // The next camera's capabilities are not known until its HAL opens.
    ++m_generation;
    m_focusTimeout.stop();
    m_captureAfterFocus = false;
    setFocusStatus(FocusIdle);
    if (m_controlsReady) {
        m_controlsReady = false;
        m_supportedFlash.clear();
        m_supportedFocus.clear();
        m_supportedWb.clear();
        m_supportedScene.clear();
        m_supportedColorTone.clear();
        m_supportedFlicker.clear();
        m_supportedIso.clear();
        m_minEv = m_maxEv = 0;
        m_zoomRatios.clear();
        m_maxFocusAreas = 0;
        m_hdrSceneMode = m_hdrImageMode = m_zslImageMode = false;
        emit controlsChanged();
    }

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

    // The same bin Qt would parse from the description, inside one of ours
    // that shows us droidcamsrc's autofocus messages (see droidcamerabin.h).
    GError *error = nullptr;
    GstElement *inner = gst_parse_bin_from_description(desc.toUtf8().constData(), TRUE, &error);
    if (!inner) {
        qWarning() << "DroidCameraFactory: cannot build the camera bin:"
                   << (error ? error->message : "unknown");
        g_clear_error(&error);
        return nullptr;
    }
    g_clear_error(&error);

    const unsigned generation = m_generation;
    QPointer<DroidCameraFactory> guard(this);
    GstElement *outer = droid_camera_bin_new("droidcamerabin", inner, [guard, generation](GstMessage *message) {
        const GstStructure *s = gst_message_get_structure(message);
        if (!s)
            return;
        const QString name = QString::fromLatin1(gst_structure_get_name(s));
        if (name != QLatin1String(GST_PHOTOGRAPHY_AUTOFOCUS_DONE) && name != QLatin1String("focus-move"))
            return;
        int status = 0;
        gst_structure_get_int(s, "status", &status);
        // A HAL thread: the factory is only touched on the GUI thread.
        QMetaObject::invokeMethod(QCoreApplication::instance(), [guard, name, status, generation] {
            if (guard)
                guard->handleElementMessage(name, status, generation);
        }, Qt::QueuedConnection);
    });
    if (!outer) {
        qWarning() << "DroidCameraFactory: the camera bin has no source pad";
        return nullptr;
    }

    if (GstElement *cam = gst_bin_get_by_name(GST_BIN(outer), "droidcam")) {
        connectCamera(cam, generation);
        gst_object_unref(cam);
    }

    // Qt takes the floating reference.
    auto *source = new QGStreamerVideoSource(outer, this);
    m_videoSource = source;

    // Full-resolution JPEGs from the HAL arrive on the imgsrc appsink when
    // a capture is triggered; the callback runs on a streaming thread.
    if (GstElement *bin = source->gstElement()) {
        GstElement *sink = gst_bin_get_by_name(GST_BIN(bin), "droidimgsink");
        if (sink) {
            g_signal_connect(sink, "new-sample",
                G_CALLBACK((+[](GstElement *appsink, gpointer user) -> GstFlowReturn {
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
                })), this);
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
    if (!m_pendingImagePath.isEmpty() || m_captureAfterFocus) {
        gst_object_unref(cam);
        emit imageCaptureError(QStringLiteral("a capture is already in progress"));
        return false;
    }

    m_pendingImagePath = filePath;

    /* In a one-shot focus mode the lens sits wherever the last focus left it,
     * so focus first and shoot when the HAL says it is done - as the camera
     * app of the legacy webOS phones did. Continuous modes are already in
     * focus, and a focus that just succeeded on a tap is kept. */
    if (autofocusBeforeCapture()) {
        m_captureAfterFocus = true;
        setFocusStatus(FocusRunning);
        gst_photography_set_autofocus(GST_PHOTOGRAPHY(cam), TRUE);
        m_focusTimeout.start(kFocusBeforeCaptureMs);
    } else {
        releaseShutter();
    }
    gst_object_unref(cam);
    return true;
#else
    Q_UNUSED(filePath);
    return false;
#endif
}

bool DroidCameraFactory::autofocusBeforeCapture() const
{
    if (m_focusStatus == FocusSucceeded || !m_supportedFocus.contains(m_focusMode))
        return false;
    return m_focusMode == QLatin1String("auto") || m_focusMode == QLatin1String("macro");
}

void DroidCameraFactory::releaseShutter()
{
    m_captureAfterFocus = false;
    m_focusTimeout.stop();
    GstElement *cam = camera();
    if (!cam) {
        m_pendingImagePath.clear();
        emit imageCaptureError(QStringLiteral("no active droid camera"));
        return;
    }
    emit captureStarted();
    g_signal_emit_by_name(cam, "start-capture");
    gst_object_unref(cam);

    /* A HAL that takes the capture and never delivers the JPEG would otherwise
     * leave every later shutter press refused as "already in progress". */
    const unsigned serial = ++m_captureSerial;
    const QString path = m_pendingImagePath;
    QTimer::singleShot(kCaptureTimeoutMs, this, [this, serial, path] {
        if (m_captureSerial != serial || m_pendingImagePath.isEmpty())
            return;
        m_pendingImagePath.clear();
        qWarning() << "DroidCameraFactory: no image arrived for" << path;
        emit imageCaptureError(QStringLiteral("the camera did not deliver the picture"));
    });
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

    /* A focus the shot locked is the shot's; the next one focuses afresh. */
    if (m_focusStatus != FocusIdle) {
        if (GstElement *cam = camera()) {
            gst_photography_set_autofocus(GST_PHOTOGRAPHY(cam), FALSE);
            gst_object_unref(cam);
        }
        setFocusStatus(FocusIdle);
    }

    emit imageSaved(path);
}

bool DroidCameraFactory::recording() const
{
    // Also while a hardware recording is being set up, so the UI shows it at once.
    return m_recBin != nullptr || m_starting;
}

/* The EOS that stop-capture pushes through vidsrc leaves the pad in the EOS state, and droidcamsrc
 * only clears it again at start-capture. Negotiating vidsrc before that - when the next recording
 * sets the camera to video mode, or when the pad is given back to the idle sink after this one and the
 * camera goes back to image mode - pushes the caps event onto an EOS pad ("We're EOS"), fails, and
 * droidcamsrc posts "failed to negotiate vidsrc", which Qt's capture session reports as an error. A
 * recording was not affected, but each one logged it. A FLUSH_STOP clears the state. */
static void clearVidsrcEos(GstElement *cam)
{
    if (GstPad *pad = gst_element_get_static_pad(cam, "vidsrc")) {
        gst_pad_push_event(pad, gst_event_new_flush_stop(TRUE));
        gst_object_unref(pad);
    }
}

/* Hardware recording is used when the environment asks for it, or, when it does not say, when the
 * device installed the marker file (see startHwRecording()). */
static bool hwRecordingWanted()
{
    const QString hwEnv = qEnvironmentVariable("LUNEOS_CAMERA_HW_RECORDING");
    return hwEnv.isEmpty()
        ? QFileInfo::exists(QStringLiteral("/etc/luneos/camera-hw-recording"))
        : hwEnv == QLatin1String("1");
}

/* Record in the file how the frames are to be turned for display: mp4mux writes the
 * image-orientation tag into the video track's matrix. The frames themselves stay as the sensor
 * delivers them, so this costs nothing at record time. */
static void tagRecordingRotation(GstElement *rec, int rotation)
{
    rotation = ((rotation % 360) + 360) % 360;
    if (rotation % 90)
        return;
    GstElement *mux = gst_bin_get_by_name(GST_BIN(rec), "recmux");
    if (!mux)
        return;
    const QByteArray orientation = "rotate-" + QByteArray::number(rotation);
    gst_tag_setter_add_tags(GST_TAG_SETTER(mux), GST_TAG_MERGE_REPLACE,
                            GST_TAG_IMAGE_ORIENTATION, orientation.constData(), nullptr);
    gst_object_unref(mux);
}

/* gst-droid tags its viewfinder with the sensor's mounting ("rotate-90"). Through the tee that tag
 * reaches the software recorder's muxer and takes the place of the one tagRecordingRotation() set,
 * which also knows how the device is held. Take it out on the way in. */
static GstPadProbeReturn dropOrientationTag(GstPad *, GstPadProbeInfo *info, gpointer)
{
    GstEvent *event = GST_PAD_PROBE_INFO_EVENT(info);
    if (GST_EVENT_TYPE(event) != GST_EVENT_TAG)
        return GST_PAD_PROBE_OK;
    GstTagList *tags = nullptr;
    gst_event_parse_tag(event, &tags);
    if (!gst_tag_list_get_tag_size(tags, GST_TAG_IMAGE_ORIENTATION))
        return GST_PAD_PROBE_OK;

    GstTagList *rest = gst_tag_list_copy(tags);
    gst_tag_list_remove_tag(rest, GST_TAG_IMAGE_ORIENTATION);
    if (gst_tag_list_is_empty(rest)) {
        gst_tag_list_unref(rest);
        return GST_PAD_PROBE_DROP;
    }
    gst_event_unref(event);
    GST_PAD_PROBE_INFO_DATA(info) = gst_event_new_tag(rest);
    return GST_PAD_PROBE_OK;
}

bool DroidCameraFactory::startRecording(const QString &filePath, int rotation)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
    if (!source || !source->gstElement() || m_recBin || m_starting) {
        emit videoCaptureError(QStringLiteral("cannot start recording"));
        return false;
    }
    m_recordingRotation = rotation;

    // The recorders are linked to elements of the camera's own bin, so they go in there.
    GstElement *bin = droid_camera_bin_contents(source->gstElement());
    if (!bin) {
        emit videoCaptureError(QStringLiteral("cannot start recording"));
        return false;
    }

    QDir().mkpath(QFileInfo(filePath).absolutePath());

    // Preferred: hardware H264 through droidcamsrc's recorder mode. The
    // DroidMediaRecorder attaches the encoder to the camera session inside
    // the Android layer and vidsrc emits encoded frames, independent of
    // the raw viewfinder (needs the gst-droid raw-preview-recorder patch).
    //
    // Setting it up takes seconds (the audio source is tried out, the camera
    // reconfigures for video, the encoder is created), so it is done on a
    // thread of its own and the UI stays alive: a user whose tap seems to do
    // nothing taps again, and with the UI blocked that tap was delivered the
    // moment the start returned, as a stop. recording() is true meanwhile, so
    // the UI shows the recording at once, and a stop asked for before the
    // recorder is up is carried out as soon as it is.
    if (hwRecordingWanted()) {
        m_starting = true;
        m_stopAfterStart = false;
        m_pendingVideoPath = filePath;
        emit recordingChanged();
        gst_object_ref(bin);
        std::thread([this, bin, filePath] {
            GstElement *rec = startHwRecording(bin, filePath);
            QMetaObject::invokeMethod(this, [this, bin, filePath, rec] {
                m_starting = false;
                if (rec) {
                    hwRecordingStarted(rec, filePath);
                } else {
                    // The hardware recorder could not be set up: record in software instead.
                    m_pendingVideoPath.clear();
                    m_stopAfterStart = false;
                    if (!startSwRecording(bin, filePath))
                        emit recordingChanged();
                }
                gst_object_unref(bin);
            }, Qt::QueuedConnection);
        }).detach();
        return true;
    }

    return startSwRecording(bin, filePath);
#else
    Q_UNUSED(filePath);
    Q_UNUSED(rotation);
    return false;
#endif
}

bool DroidCameraFactory::startSwRecording(GstElement *bin, const QString &filePath)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
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
        "pulsesrc name=recaudio device=%2 ! audioconvert ! "
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
    tagRecordingRotation(rec, m_recordingRotation);
    if (GstPad *recsink = gst_element_get_static_pad(rec, "sink")) {
        gst_pad_add_probe(recsink, GST_PAD_PROBE_TYPE_EVENT_DOWNSTREAM, dropOrientationTag,
                          nullptr, nullptr);
        gst_object_unref(recsink);
    }

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
    m_stopRequested = false;
    m_pendingVideoPath = filePath;
    qInfo() << "DroidCameraFactory: recording to" << filePath;
    emit recordingChanged();
    return true;
#else
    Q_UNUSED(bin); Q_UNUSED(filePath);
    return false;
#endif
}

void DroidCameraFactory::stopRecording()
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    /* A stop asked for while the hardware recorder is still being set up (the
     * start runs on a worker thread, see startRecording()) is carried out when it
     * is up. A stop that is already under way needs no second one. */
    if (m_starting) {
        qInfo() << "DroidCameraFactory: stop asked for while the recorder starts; stopping once it is up";
        m_stopAfterStart = true;
        return;
    }
    if (!m_recBin)
        return;
    if (m_stopRequested)
        return;
    m_stopRequested = true;

    if (m_hwRecording) {
        auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
        if (source && source->gstElement()) {
            GstElement *cam =
                gst_bin_get_by_name(GST_BIN(source->gstElement()), "droidcam");
            if (cam) {
                /* droidcamsrc stops the recorder and pushes EOS through
                 * vidsrc; the filesink probe fires finishHwRecording().
                 *
                 * Off the UI thread: stop-capture reaches droidmedia's
                 * recorder, and when the vendor stack has wedged - the camera
                 * delivering frames CameraSource drops for want of a memory
                 * base, the encoder never consuming - it does not return.
                 * Emitting it inline freezes the whole application. */
                std::thread([cam] {
                    g_signal_emit_by_name(cam, "stop-capture");
                    gst_object_unref(cam);
                }).detach();
            }
        }
        /* A recorder that never delivered a frame (the video hardware is wedged, say) cannot
         * finish: no EOS comes out of it, so the recording would stay on for ever. Give up on it
         * instead, once stop-capture has had a moment. */
        if (m_hwFrames.load() == 0) {
            qWarning() << "DroidCameraFactory: the hardware recorder has produced no frames; abandoning the recording";
            QTimer::singleShot(1000, this, [this] {
                if (m_recBin && m_hwRecording)
                    finishHwRecording(false);
            });
            return;
        }

        /* The recording's audio source (if any) is not fed by droidcamsrc, so
         * it gets its own EOS or mp4mux waits for it for ever and never writes
         * its moov atom; see the software path below. From a thread of its own,
         * as there. */
        if (m_recBin) {
            GstElement *audiosrc =
                gst_bin_get_by_name(GST_BIN(static_cast<GstElement *>(m_recBin)), "recaudio");
            if (audiosrc) {
                std::thread([audiosrc] {
                    gst_element_send_event(audiosrc, gst_event_new_eos());
                    gst_object_unref(audiosrc);
                    qInfo() << "DroidCameraFactory: audio EOS delivered (hardware recording)";
                }).detach();
            }
        }
        return;
    }

    if (!m_recBin || !m_recTeePad)
        return;

    qInfo() << "DroidCameraFactory: stopping recording";
    // Only this recording: a new one may have started within the 8 s.
    const QString stoppedPath = m_pendingVideoPath;
    QTimer::singleShot(8000, this, [this, stoppedPath] {
        if (m_recBin && m_pendingVideoPath == stoppedPath)
            qWarning() << "DroidCameraFactory: EOS has not reached the file sink 8 s after stopRecording of"
                       << stoppedPath;
    });

    auto *teepad = static_cast<GstPad *>(m_recTeePad);

    // Block the tee branch, unlink it, then run EOS through the encoder so
    // mp4mux writes its moov atom before the branch is torn down.
    gst_pad_add_probe(teepad, GST_PAD_PROBE_TYPE_IDLE,
        [](GstPad *pad, GstPadProbeInfo *, gpointer user) -> GstPadProbeReturn {
            auto *self = static_cast<DroidCameraFactory *>(user);
            auto *rec = static_cast<GstElement *>(self->m_recBin);

            GstPad *sinkpad = gst_element_get_static_pad(rec, "sink");
            gst_pad_unlink(pad, sinkpad);

            qInfo() << "DroidCameraFactory: recording branch idle, sending EOS";

            // EOS into the video branch first. The branch is unlinked from the
            // tee, so no more video arrives: if the audio EOS went first and
            // blocked (the audio source's thread pushing into an mp4mux that is
            // waiting for video), the video EOS would never be sent, mp4mux
            // would never write its moov atom, and this callback - which runs
            // on the viewfinder's streaming thread - would hang that too.
            gst_pad_send_event(sinkpad, gst_event_new_eos());
            gst_object_unref(sinkpad);

            // The audio source (if any) gets its own EOS so both tracks
            // finalize, from a thread of its own: send_event on a live source
            // can wait for its streaming thread. It is looked up by the name
            // the description gives it: its automatic name (pulsesrc0, 1, 2 ..)
            // depends on how many pulsesrc elements the process has made, and
            // audioSourceUsable() makes one first, so "pulsesrc0" was never it
            // and no audio EOS went out, which left mp4mux waiting for it.
            GstElement *audiosrc =
                gst_bin_get_by_name(GST_BIN(rec), "recaudio");
            if (audiosrc) {
                std::thread([audiosrc] {
                    gst_element_send_event(audiosrc, gst_event_new_eos());
                    gst_object_unref(audiosrc);
                    qInfo() << "DroidCameraFactory: audio EOS delivered";
                }).detach();
            }

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
    if (GstElement *bin = source ? droid_camera_bin_contents(source->gstElement()) : nullptr) {
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
    m_stopRequested = false;
    emit recordingChanged();
    qInfo() << "DroidCameraFactory: saved recording to" << path;
    emit videoSaved(path);
#endif
}

GstElement *DroidCameraFactory::startHwRecording(GstElement *bin,
                                                  const QString &filePath)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    /* Opt-in only. On a device whose vendor recorder accepts the session but
     * never delivers, there is no way back: stop-capture blocks inside
     * droidmedia holding GStreamer's locks, and every streaming thread and
     * the UI thread pile up behind it - the application deadlocks and the
     * software encoder cannot be started, because it needs the same
     * pipeline. Since that cannot be recovered from in process, it must not
     * be risked by default. Set LUNEOS_CAMERA_HW_RECORDING=1 to try it, or
     * install /etc/luneos/camera-hw-recording on a device where it is known to
     * work (LUNEOS_CAMERA_HW_RECORDING=0 turns it off again). */
    GstElement *cam = gst_bin_get_by_name(GST_BIN(bin), "droidcam");
    GstElement *vidsink = gst_bin_get_by_name(GST_BIN(bin), "vidsink");
    if (!cam || !vidsink) {
        if (cam) gst_object_unref(cam);
        if (vidsink) gst_object_unref(vidsink);
        return nullptr;
    }

    // The audio queue is unbounded: the hardware encoder hands over video in bursts, mp4mux
    // holds the audio until the video catches up, and the default one second of queue then
    // fills, stalls the source and drops most of the audio. The video gets a queue too: vidsrc
    // reports next to no maximum latency, below the audio source's minimum, and mp4mux then
    // warns "Impossible to configure latency" for every buffer it aggregates.
    const QByteArray audioSource = recordingAudioSource();
    const QString avDesc = QStringLiteral(
        "queue ! h264parse ! mp4mux name=recmux ! "
        "filesink name=recsink async=false location=\"%1\" "
        "pulsesrc name=recaudio device=%2 ! audioconvert ! "
        "avenc_aac ! queue max-size-buffers=0 max-size-bytes=0 max-size-time=0 ! recmux.")
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
        return nullptr;
    }
    gst_element_set_name(rec, "hwrecbin");
    tagRecordingRotation(rec, m_recordingRotation);

    // vidsrc is quiescent outside recording, so relinking it is safe.
    GstPad *vidsrcpad = gst_element_get_static_pad(cam, "vidsrc");
    GstPad *oldsink = gst_element_get_static_pad(vidsink, "sink");
    gst_pad_unlink(vidsrcpad, oldsink);
    gst_object_unref(oldsink);

    gst_bin_add(GST_BIN(bin), rec);
    // PAUSED, not PLAYING: the audio source must not start capturing until the video does (see
    // below); the camera takes seconds to reconfigure for video and audio from before that would
    // run ahead of the video in the file.
    gst_element_set_state(rec, GST_STATE_PAUSED);
    GstPad *recsink = gst_element_get_static_pad(rec, "sink");
    /* No caps check: it asks vidsrc for its caps, which is answered under droidcamsrc's device
     * lock (so it can block for a second or two behind the camera) and, depending on how far the
     * camera's parameters have been read, may list only the raw formats, failing the link with
     * "no common format". The real negotiation happens when the mode is set below. */
    const bool linked = gst_pad_link_full(vidsrcpad, recsink, GST_PAD_LINK_CHECK_HIERARCHY)
        == GST_PAD_LINK_OK;
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
        return nullptr;
    }
    gst_object_unref(vidsrcpad);

    // Video mode renegotiates vidsrc against h264parse, selecting the
    // hardware encoder; then start-capture begins the recording.
    clearVidsrcEos(cam);
    g_object_set(cam, "mode", 2, nullptr);

    /* droidcamsrc asks the encoder for 12 Mbit/s unless told otherwise, which the TouchPad's
     * encoder answered with about 5 Mbit/s at 640x480 - far more than the picture needs. Scale
     * the target with the negotiated size instead: 6 bit/s per pixel is 1.8 Mbit/s at 640x480,
     * 5.5 at 720p and 12 at 1080p. Not with the frame rate: the caps carry the top of the HAL's
     * range (31 fps on the TouchPad), not what the sensor delivers (15 fps indoors), and the
     * encoder spreads the target over the rate the caps claim, so the files come out at about
     * half of it there. It must be set before start-capture, which creates the encoder. */
    if (GstPad *pad = gst_element_get_static_pad(cam, "vidsrc")) {
        if (GstCaps *caps = gst_pad_get_current_caps(pad)) {
            int width = 0, height = 0;
            const GstStructure *s = gst_caps_get_structure(caps, 0);
            if (gst_structure_get_int(s, "width", &width)
                && gst_structure_get_int(s, "height", &height) && width > 0 && height > 0) {
                const qint64 bitrate = qBound(qint64(1000000), qint64(width) * height * 6, qint64(12000000));
                g_object_set(cam, "target-bitrate", int(bitrate), nullptr);
            }
            gst_caps_unref(caps);
        }
        gst_object_unref(pad);
    }

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

    /* Count what actually reaches the recording bin. droidcamsrc happily
     * reports a started capture even when the Android side never delivers:
     * the vendor encoder is created and the camera configures an encoder
     * stream, but CameraSource sits in "Timed out waiting for incoming
     * camera video frames" and vidsrc pushes nothing at all. */
    m_hwFrames.store(0);
    GstPad *recsinkpad = gst_element_get_static_pad(rec, "sink");
    gst_pad_add_probe(recsinkpad, GST_PAD_PROBE_TYPE_BUFFER,
        [](GstPad *, GstPadProbeInfo *, gpointer u) -> GstPadProbeReturn {
            static_cast<DroidCameraFactory *>(u)->m_hwFrames.fetch_add(1);
            return GST_PAD_PROBE_OK;
        }, this, nullptr);
    gst_object_unref(recsinkpad);

    /* droidcamsrc's recorder stamps the video from zero at start-capture, but
     * the audio source lives in the already running pipeline, so its buffers
     * carry the time since the pipeline started (the viewfinder had been up for
     * ~20 s). Left like that the muxer held the audio back until the video
     * ended: the audio track began that late in the file and most of it was
     * lost. Delay the video by the running time now, so both are on the
     * pipeline's timeline (the software path gets that for free from the
     * viewfinder's own timestamps). A positive pad offset is what this is for;
     * a negative one on the audio side does not work. */
    {
        GstClock *clock = gst_element_get_clock(bin);
        if (clock) {
            const GstClockTime base = gst_element_get_base_time(bin);
            const GstClockTime now = gst_clock_get_time(clock);
            if (GST_CLOCK_TIME_IS_VALID(base) && now > base) {
                if (GstPad *rsink = gst_element_get_static_pad(rec, "sink")) {
                    gst_pad_set_offset(rsink, static_cast<gint64>(now - base));
                    gst_object_unref(rsink);
                }
            }
            gst_object_unref(clock);
        }
    }

    /* Audio starts now, with the video: the recording bin goes to PLAYING at the moment the
     * running time for the offset above is taken. */
    gst_element_sync_state_with_parent(rec);

    g_signal_emit_by_name(cam, "start-capture");
    gst_object_unref(cam);
    gst_object_unref(vidsink);

    return rec;
#else
    Q_UNUSED(bin); Q_UNUSED(filePath);
    return nullptr;
#endif
}

void DroidCameraFactory::hwRecordingStarted(GstElement *rec, const QString &filePath)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    m_recBin = rec;
    m_hwRecording = true;
    m_stopRequested = false;
    m_pendingVideoPath = filePath;
    qInfo() << "DroidCameraFactory: HW recording to" << filePath;
    emit recordingChanged();

    /* Report a recorder that took the session and then produced nothing, so
     * the zero-byte file it leaves behind has an explanation in the log.
     * Nothing is torn down here on purpose - see the note in startHwRecording(). */
    QTimer::singleShot(kHwRecordingGraceMs, this, [this] {
        if (m_hwRecording && m_hwFrames.load() == 0)
            qWarning() << "DroidCameraFactory: hardware recorder produced no "
                          "frames after" << kHwRecordingGraceMs
                       << "ms; the recording will be empty";
    });

    if (m_stopAfterStart) {
        m_stopAfterStart = false;
        stopRecording();
    }
#else
    Q_UNUSED(rec); Q_UNUSED(filePath);
#endif
}

void DroidCameraFactory::finishHwRecording(bool saved)
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
    auto *rec = static_cast<GstElement *>(m_recBin);
    if (!rec)
        return;

    gst_element_set_state(rec, GST_STATE_NULL);
    if (GstElement *bin = source ? droid_camera_bin_contents(source->gstElement()) : nullptr) {
        GstElement *cam = gst_bin_get_by_name(GST_BIN(bin), "droidcam");
        GstElement *vidsink = gst_bin_get_by_name(GST_BIN(bin), "vidsink");
        gst_bin_remove(GST_BIN(bin), rec);
        if (cam && vidsink) {
            clearVidsrcEos(cam);
            GstPad *vidsrcpad = gst_element_get_static_pad(cam, "vidsrc");
            GstPad *os = gst_element_get_static_pad(vidsink, "sink");
            gst_pad_link_full(vidsrcpad, os, GST_PAD_LINK_CHECK_HIERARCHY);
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
    m_stopRequested = false;
    emit recordingChanged();
    if (saved) {
        qInfo() << "DroidCameraFactory: saved HW recording to" << path;
        emit videoSaved(path);
    } else {
        // Nothing was recorded: do not leave an empty file behind.
        QFile::remove(path);
        qWarning() << "DroidCameraFactory: abandoned the empty HW recording" << path;
        emit videoCaptureError(QStringLiteral("the hardware recorder produced no video"));
    }
#endif
}

GstElement *DroidCameraFactory::camera() const
{
#ifdef HAVE_QGSTREAMER_VIDEO_SOURCE
    auto *source = qobject_cast<QGStreamerVideoSource *>(m_videoSource);
    if (!source || !source->gstElement())
        return nullptr;
    return gst_bin_get_by_name(GST_BIN(source->gstElement()), "droidcam");
#else
    return nullptr;
#endif
}

/* A GVariant "ai" property as a list; gst-droid leaves it NULL when the HAL
 * listed nothing. */
static QList<int> intListProperty(GstElement *cam, const char *property)
{
    QList<int> values;
    GVariant *variant = nullptr;
    g_object_get(cam, property, &variant, nullptr);
    if (!variant)
        return values;
    if (g_variant_is_of_type(variant, G_VARIANT_TYPE("ai"))) {
        gsize n = 0;
        const gint32 *items = static_cast<const gint32 *>(
            g_variant_get_fixed_array(variant, &n, sizeof(gint32)));
        for (gsize i = 0; i < n; ++i)
            values.append(items[i]);
    }
    g_variant_unref(variant);
    return values;
}

void DroidCameraFactory::connectCamera(GstElement *cam, unsigned generation)
{
    struct Context {
        QPointer<DroidCameraFactory> factory;
        unsigned generation;
    };
    auto *context = new Context{ QPointer<DroidCameraFactory>(this), generation };

    /* droidcamsrc announces "supported-image-modes" right after it has opened
     * the HAL and read its parameters, on the thread changing its state from
     * NULL to READY - before the preview starts. Everything the HAL can do is
     * read here, in that thread, while nothing else is touching the camera's
     * parameter table: "device-parameters" hands out that table itself, not a
     * copy, and the GUI thread must not walk it while droidcamsrc writes it. */
    g_signal_connect_data(cam, "notify::supported-image-modes",
        G_CALLBACK((+[](GstElement *element, GParamSpec *, gpointer user) {
            auto *ctx = static_cast<Context *>(user);
            Capabilities caps;
            caps.flash = intListProperty(element, "supported-flash-modes");
            caps.focus = intListProperty(element, "supported-focus-modes");
            caps.wb = intListProperty(element, "supported-wb-modes");
            caps.scene = intListProperty(element, "supported-scene-modes");
            caps.colorTone = intListProperty(element, "supported-color-tones");
            caps.iso = intListProperty(element, "supported-iso-speeds");

            gfloat minEv = 0, maxEv = 0;
            g_object_get(element, "min-ev-compensation", &minEv,
                         "max-ev-compensation", &maxEv, nullptr);
            caps.minEv = minEv;
            caps.maxEv = maxEv;

            gpointer modes = nullptr;
            g_object_get(element, "supported-image-modes", &modes, nullptr);
            if (auto *array = static_cast<GArray *>(modes)) {
                for (guint i = 0; i < array->len; ++i) {
                    const gint mode = g_array_index(array, gint, i);
                    // Combinations are listed as well; only the single modes matter here.
                    if (mode == 0x1)
                        caps.zslImageMode = true;
                    else if (mode == 0x2)
                        caps.hdrImageMode = true;
                }
                g_array_unref(array);
            }

            gpointer table = nullptr;
            g_object_get(element, "device-parameters", &table, nullptr);
            if (auto *params = static_cast<GHashTable *>(table)) {
                auto value = [params](const char *key) {
                    return QString::fromUtf8(static_cast<const char *>(g_hash_table_lookup(params, key)));
                };
                if (value("zoom-supported") == QLatin1String("true"))
                    caps.zoomRatios = CameraControls::parseZoomRatios(value("zoom-ratios"));
                caps.maxFocusAreas = value("max-num-focus-areas").toInt();
                /* The flicker modes are not part of droidcamsrc's capability
                 * properties; the HAL lists them as "antibanding-values". */
                const QStringList antibanding = value("antibanding-values").split(QLatin1Char(','), Qt::SkipEmptyParts);
                for (const QString &mode : antibanding) {
                    const int v = CameraControls::modeValue(CameraControls::ModeKind::Flicker, mode);
                    if (v >= 0)
                        caps.flicker.append(v);
                }
            }

            const QPointer<DroidCameraFactory> factory = ctx->factory;
            const unsigned gen = ctx->generation;
            QMetaObject::invokeMethod(QCoreApplication::instance(), [factory, caps, gen] {
                if (factory)
                    factory->capabilitiesReady(caps, gen);
            }, Qt::QueuedConnection);
        })),
        context,
        +[](gpointer data, GClosure *) { delete static_cast<Context *>(data); },
        GConnectFlags(0));

    /* The zoom range is only set once the preview has started (READY to
     * PAUSED); a zoom asked for before then is refused by the property's
     * range, so apply it again now. */
    auto *zoomContext = new Context{ QPointer<DroidCameraFactory>(this), generation };
    g_signal_connect_data(cam, "notify::max-zoom",
        G_CALLBACK((+[](GstElement *, GParamSpec *, gpointer user) {
            auto *ctx = static_cast<Context *>(user);
            const QPointer<DroidCameraFactory> factory = ctx->factory;
            const unsigned gen = ctx->generation;
            QMetaObject::invokeMethod(QCoreApplication::instance(), [factory, gen] {
                if (factory && factory->m_generation == gen && factory->m_controlsReady)
                    factory->setZoom(factory->m_zoom);
            }, Qt::QueuedConnection);
        })),
        zoomContext,
        +[](gpointer data, GClosure *) { delete static_cast<Context *>(data); },
        GConnectFlags(0));
}

void DroidCameraFactory::capabilitiesReady(const Capabilities &caps, unsigned generation)
{
    if (generation != m_generation)
        return;

    using namespace CameraControls;
    m_supportedFlash = modeNames(ModeKind::Flash, caps.flash);
    m_supportedFocus = modeNames(ModeKind::Focus, caps.focus);
    m_supportedWb = modeNames(ModeKind::WhiteBalance, caps.wb);
    m_supportedColorTone = modeNames(ModeKind::ColorTone, caps.colorTone);
    m_supportedFlicker = modeNames(ModeKind::Flicker, caps.flicker);

    /* HDR is offered as its own switch rather than as one scene among many:
     * that is how people look for it, and some HALs only have it as an image
     * mode. */
    QStringList scenes = modeNames(ModeKind::Scene, caps.scene);
    m_hdrSceneMode = scenes.removeAll(QStringLiteral("hdr")) > 0;
    m_supportedScene = scenes;

    m_supportedIso.clear();
    for (int iso : caps.iso) {
        if (!m_supportedIso.contains(iso))
            m_supportedIso.append(iso);
    }
    m_minEv = caps.minEv;
    m_maxEv = caps.maxEv;
    m_zoomRatios = caps.zoomRatios;
    m_maxFocusAreas = caps.maxFocusAreas;
    m_hdrImageMode = caps.hdrImageMode;
    m_zslImageMode = caps.zslImageMode;
    m_controlsReady = true;

    qInfo() << "DroidCameraFactory: flash" << m_supportedFlash << "focus" << m_supportedFocus
            << "wb" << m_supportedWb << "scene" << m_supportedScene << "hdr scene" << m_hdrSceneMode
            << "image modes hdr/zsl" << m_hdrImageMode << m_zslImageMode
            << "tones" << m_supportedColorTone << "iso" << m_supportedIso
            << "ev" << m_minEv << m_maxEv << "zoom x" << maximumZoom()
            << "focus areas" << m_maxFocusAreas;

    emit controlsChanged();
    applyControls();
}

void DroidCameraFactory::setEnumProperty(const char *property, int value)
{
    GstElement *cam = camera();
    if (!cam)
        return;
    g_object_set(cam, property, value, nullptr);
    gst_object_unref(cam);
}

/* Exposure compensation, clamped to the property's own range rather than to
 * min/max-ev-compensation: those are computed from the HAL's step in a
 * different precision (4.0000081 against a range ending at 4.0 on the Pixel
 * 3a), and a value a hair outside the range is refused outright. */
static void setExposureOn(GstElement *cam, qreal ev)
{
    GParamSpec *spec = g_object_class_find_property(G_OBJECT_GET_CLASS(cam), GST_PHOTOGRAPHY_PROP_EV_COMP);
    if (!spec || !G_IS_PARAM_SPEC_FLOAT(spec))
        return;
    const GParamSpecFloat *range = G_PARAM_SPEC_FLOAT(spec);
    g_object_set(cam, GST_PHOTOGRAPHY_PROP_EV_COMP,
                 qBound(range->minimum, gfloat(ev), range->maximum), nullptr);
}

void DroidCameraFactory::applyControls()
{
    if (!m_controlsReady)
        return;

    using namespace CameraControls;
    if (m_supportedFlash.contains(m_flashMode))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_FLASH_MODE, modeValue(ModeKind::Flash, m_flashMode));
    if (m_supportedFocus.contains(m_focusMode))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_FOCUS_MODE, modeValue(ModeKind::Focus, m_focusMode));
    if (m_supportedWb.contains(m_wbMode))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_WB_MODE, modeValue(ModeKind::WhiteBalance, m_wbMode));
    if (m_supportedColorTone.contains(m_colorTone))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_COLOR_TONE, modeValue(ModeKind::ColorTone, m_colorTone));
    if (m_supportedFlicker.contains(m_flickerMode))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_FLICKER_MODE, modeValue(ModeKind::Flicker, m_flickerMode));
    applySceneMode();
    applyImageMode();

    if (GstElement *cam = camera()) {
        if (m_isoSpeed == 0 || m_supportedIso.contains(m_isoSpeed))
            g_object_set(cam, GST_PHOTOGRAPHY_PROP_ISO_SPEED, guint(m_isoSpeed), nullptr);
        if (m_maxEv > m_minEv)
            setExposureOn(cam, m_ev);
        g_object_set(cam, "video-torch", gboolean(m_torch), nullptr);
        gst_object_unref(cam);
    }
    setZoom(m_zoom);
}

void DroidCameraFactory::applySceneMode()
{
    if (!m_controlsReady)
        return;
    using namespace CameraControls;
    QString scene = m_supportedScene.contains(m_sceneMode) ? m_sceneMode : QStringLiteral("auto");
    // An HDR scene mode is the HAL's own multi-frame merge; it replaces the scene.
    if (m_hdrEnabled && m_hdrSceneMode)
        scene = QStringLiteral("hdr");
    if (scene == QLatin1String("hdr") || m_supportedScene.contains(scene))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_SCENE_MODE, modeValue(ModeKind::Scene, scene));
}

void DroidCameraFactory::applyImageMode()
{
    if (!m_controlsReady || (!m_zslImageMode && !m_hdrImageMode))
        return;
    guint flags = 0;
    if (m_zslEnabled && m_zslImageMode)
        flags |= 0x1;
    // Only when there is no HDR scene mode, which is preferred (see applySceneMode()).
    if (m_hdrEnabled && m_hdrImageMode && !m_hdrSceneMode)
        flags |= 0x2;
    // ZSL and HDR together is a combination of its own that few HALs have.
    if (flags == 0x3)
        flags = 0x2;
    GstElement *cam = camera();
    if (!cam)
        return;
    g_object_set(cam, "image-mode", flags, nullptr);
    gst_object_unref(cam);
}

/* Records a newly chosen mode; false when it is the one already chosen. */
static bool chooseMode(QString &chosen, const QString &mode)
{
    if (chosen == mode)
        return false;
    chosen = mode;
    return true;
}

void DroidCameraFactory::setFlashMode(const QString &mode)
{
    if (!chooseMode(m_flashMode, mode))
        return;
    emit flashModeChanged();
    if (m_supportedFlash.contains(mode))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_FLASH_MODE,
                        CameraControls::modeValue(CameraControls::ModeKind::Flash, mode));
}

void DroidCameraFactory::setFocusMode(const QString &mode)
{
    if (!chooseMode(m_focusMode, mode))
        return;
    emit focusModeChanged();
    if (m_supportedFocus.contains(mode))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_FOCUS_MODE,
                        CameraControls::modeValue(CameraControls::ModeKind::Focus, mode));
}

void DroidCameraFactory::setWhiteBalanceMode(const QString &mode)
{
    if (!chooseMode(m_wbMode, mode))
        return;
    emit whiteBalanceModeChanged();
    if (m_supportedWb.contains(mode))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_WB_MODE,
                        CameraControls::modeValue(CameraControls::ModeKind::WhiteBalance, mode));
}

void DroidCameraFactory::setColorTone(const QString &tone)
{
    if (!chooseMode(m_colorTone, tone))
        return;
    emit colorToneChanged();
    if (m_supportedColorTone.contains(tone))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_COLOR_TONE,
                        CameraControls::modeValue(CameraControls::ModeKind::ColorTone, tone));
}

void DroidCameraFactory::setFlickerMode(const QString &mode)
{
    if (!chooseMode(m_flickerMode, mode))
        return;
    emit flickerModeChanged();
    if (m_supportedFlicker.contains(mode))
        setEnumProperty(GST_PHOTOGRAPHY_PROP_FLICKER_MODE,
                        CameraControls::modeValue(CameraControls::ModeKind::Flicker, mode));
}

void DroidCameraFactory::setSceneMode(const QString &mode)
{
    if (!chooseMode(m_sceneMode, mode))
        return;
    emit sceneModeChanged();
    applySceneMode();
}

void DroidCameraFactory::setIsoSpeed(int iso)
{
    if (m_isoSpeed == iso)
        return;
    m_isoSpeed = iso;
    emit isoSpeedChanged();
    if (!m_controlsReady || (iso != 0 && !m_supportedIso.contains(iso)))
        return;
    if (GstElement *cam = camera()) {
        g_object_set(cam, GST_PHOTOGRAPHY_PROP_ISO_SPEED, guint(iso), nullptr);
        gst_object_unref(cam);
    }
}

void DroidCameraFactory::setExposureCompensation(qreal ev)
{
    if (qFuzzyCompare(m_ev + 1.0, ev + 1.0))
        return;
    m_ev = ev;
    emit exposureCompensationChanged();
    if (!m_controlsReady || m_maxEv <= m_minEv)
        return;
    if (GstElement *cam = camera()) {
        setExposureOn(cam, ev);
        gst_object_unref(cam);
    }
}

qreal DroidCameraFactory::maximumZoom() const
{
    return CameraControls::maximumZoomRatio(m_zoomRatios);
}

void DroidCameraFactory::setZoom(qreal zoom)
{
    zoom = std::max(zoom, 1.0);
    if (m_controlsReady && !m_zoomRatios.isEmpty())
        zoom = std::min(zoom, maximumZoom());
    if (!qFuzzyCompare(m_zoom, zoom)) {
        m_zoom = zoom;
        emit zoomChanged();
    }
    if (!m_controlsReady || m_zoomRatios.isEmpty())
        return;

    /* droidcamsrc's "zoom" is the Android zoom index plus one (its range is
     * 1 .. max-zoom + 1); the index picks an entry of "zoom-ratios". */
    const int index = CameraControls::zoomIndexForRatio(m_zoomRatios, zoom);
    GstElement *cam = camera();
    if (!cam)
        return;
    GParamSpec *spec = g_object_class_find_property(G_OBJECT_GET_CLASS(cam), GST_PHOTOGRAPHY_PROP_ZOOM);
    const gfloat value = gfloat(index + 1);
    // Before the preview starts the range is still the default; notify::max-zoom re-applies.
    if (spec && G_IS_PARAM_SPEC_FLOAT(spec) && value <= G_PARAM_SPEC_FLOAT(spec)->maximum)
        g_object_set(cam, GST_PHOTOGRAPHY_PROP_ZOOM, value, nullptr);
    gst_object_unref(cam);
}

void DroidCameraFactory::setHdrEnabled(bool enabled)
{
    if (m_hdrEnabled == enabled)
        return;
    m_hdrEnabled = enabled;
    emit hdrEnabledChanged();
    applySceneMode();
    applyImageMode();
}

void DroidCameraFactory::setZslEnabled(bool enabled)
{
    if (m_zslEnabled == enabled)
        return;
    m_zslEnabled = enabled;
    emit zslEnabledChanged();
    applyImageMode();
}

void DroidCameraFactory::setTorch(bool on)
{
    if (m_torch == on)
        return;
    m_torch = on;
    emit torchChanged();
    if (GstElement *cam = camera()) {
        g_object_set(cam, "video-torch", gboolean(on), nullptr);
        gst_object_unref(cam);
    }
}

/* The coordinate space the regions are given in. droidcamsrc scales it to
 * Android's -1000..1000 itself, so a square of this size maps one to one. */
static const int kRoiSpace = 2000;

static void sendRegion(GstElement *cam, const QRect &region, guint priority)
{
    GstStructure *regionStruct = gst_structure_new("region0",
        "region-x", G_TYPE_UINT, guint(region.x()),
        "region-y", G_TYPE_UINT, guint(region.y()),
        "region-w", G_TYPE_UINT, guint(region.width()),
        "region-h", G_TYPE_UINT, guint(region.height()),
        "region-priority", G_TYPE_UINT, priority,
        nullptr);

    GValue regions = G_VALUE_INIT;
    g_value_init(&regions, GST_TYPE_LIST);
    GValue item = G_VALUE_INIT;
    g_value_init(&item, GST_TYPE_STRUCTURE);
    gst_value_set_structure(&item, regionStruct);
    gst_value_list_append_and_take_value(&regions, &item);
    gst_structure_free(regionStruct);

    GstStructure *s = gst_structure_new("regions-of-interest",
        "frame-width", G_TYPE_UINT, guint(kRoiSpace),
        "frame-height", G_TYPE_UINT, guint(kRoiSpace),
        nullptr);
    gst_structure_take_value(s, "regions", &regions);

    gst_element_send_event(cam, gst_event_new_custom(GST_EVENT_CUSTOM_UPSTREAM, s));
}

void DroidCameraFactory::focusAt(qreal x, qreal y)
{
    const QRect region = CameraControls::focusRegion(QPointF(x, y), QSize(kRoiSpace, kRoiSpace));
    if (region.isEmpty() || !m_controlsReady)
        return;
    GstElement *cam = camera();
    if (!cam)
        return;

    if (m_maxFocusAreas > 0)
        sendRegion(cam, region, 1000);

    /* A fixed-focus lens has nothing to do; the metering area still applies. */
    if (m_focusMode == QLatin1String("auto") || m_focusMode == QLatin1String("macro")
        || m_focusMode == QLatin1String("continuous")) {
        gst_photography_set_autofocus(GST_PHOTOGRAPHY(cam), TRUE);
        setFocusStatus(FocusRunning);
        if (!m_captureAfterFocus)
            m_focusTimeout.start(kFocusResultMs);
    }
    gst_object_unref(cam);
}

void DroidCameraFactory::resetFocus()
{
    GstElement *cam = camera();
    if (!cam)
        return;
    if (m_maxFocusAreas > 0)
        sendRegion(cam, QRect(0, 0, 1, 1), 0);
    gst_photography_set_autofocus(GST_PHOTOGRAPHY(cam), FALSE);
    gst_object_unref(cam);
    if (!m_captureAfterFocus)
        m_focusTimeout.stop();
    setFocusStatus(FocusIdle);
}

void DroidCameraFactory::handleElementMessage(const QString &name, int status, unsigned generation)
{
    if (generation != m_generation)
        return;

    if (name == QLatin1String(GST_PHOTOGRAPHY_AUTOFOCUS_DONE)) {
        // Only answers to a focus we asked for; continuous focus reports through focus-move.
        if (m_focusStatus != FocusRunning)
            return;
        setFocusStatus(status == GST_PHOTOGRAPHY_FOCUS_STATUS_SUCCESS ? FocusSucceeded : FocusFailed);
        m_focusTimeout.stop();
        if (m_captureAfterFocus)
            releaseShutter();
    }
}

void DroidCameraFactory::setFocusStatus(FocusStatus status)
{
    if (m_focusStatus == status)
        return;
    m_focusStatus = status;
    emit focusStatusChanged();
}

QVariantList DroidCameraFactory::cameras() const
{
    static const QVariantList list = [this] {
        QVariantList result;
        const int count = cameraCount();
        if (count <= 0)
            return result;

        /* An element in the NULL state answers these from the HAL's static
         * camera info; no camera is opened. */
        GstElement *probe = gst_element_factory_make("droidcamsrc", nullptr);
        if (!probe)
            return result;
        gst_object_ref_sink(probe);
        for (int i = 0; i < count; ++i) {
            g_object_set(probe, "camera-device", i, nullptr);
            gint direction = 0, orientation = 0;
            g_object_get(probe, "sensor-direction", &direction,
                         "sensor-mount-angle", &orientation, nullptr);
            result.append(QVariantMap{
                { QStringLiteral("index"), i },
                // NEMO_GST_META_DEVICE_DIRECTION_FRONT = 1
                { QStringLiteral("facing"), direction == 1 ? QStringLiteral("front") : QStringLiteral("back") },
                { QStringLiteral("orientation"), orientation },
            });
        }
        gst_object_unref(probe);
        return result;
    }();
    return list;
}
