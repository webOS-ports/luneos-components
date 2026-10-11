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

#ifndef DROIDCAMERAFACTORY_H
#define DROIDCAMERAFACTORY_H

#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantList>

#include <atomic>

#include "cameracontrols.h"

/*
 * On Halium devices the cameras are not visible to QtMultimedia's device
 * enumeration: they sit behind the Android camera HAL, reached through
 * gst-droid's droidcamsrc element. This factory hands QML a
 * QGStreamerVideoSource wrapping a droidcamsrc bin, to be assigned to
 * CaptureSession.nativeVideoSource (Qt >= 6.12).
 *
 * It also drives the camera's controls. Qt's QCamera would do that through
 * GstPhotography, but a native video source has no QCamera, so flash, focus,
 * exposure, white balance, scene, colour effect, ISO, zoom and the HAL's own
 * HDR/ZSL modes are set on droidcamsrc here instead, and so is the JPEG
 * quality. That one needs gst-droid with LuneOS's patch 0005: unpatched,
 * droidcamsrc declares jpeg-quality as int but reads it as uint, and setting
 * it stores 0. So it is only set when it differs from droidcamsrc's own
 * default of 90, and a value that does not read back is reported.
 *
 * What a camera supports is only known once the HAL has been opened; until controlsReady the lists are
 * empty, and values set before then are kept and applied when it opens - so
 * QML can bind saved preferences straight to these properties.
 *
 * Mode values are the Android parameter names gst-droid uses ("auto", "on",
 * "continuous", "cloudy-daylight", "hdr", "mono" ...).
 */
class DroidCameraFactory : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(int cameraCount READ cameraCount CONSTANT)
    Q_PROPERTY(bool recording READ recording NOTIFY recordingChanged)

    Q_PROPERTY(bool controlsReady READ controlsReady NOTIFY controlsChanged)
    Q_PROPERTY(QStringList supportedFlashModes READ supportedFlashModes NOTIFY controlsChanged)
    Q_PROPERTY(QStringList supportedFocusModes READ supportedFocusModes NOTIFY controlsChanged)
    Q_PROPERTY(QStringList supportedWhiteBalanceModes READ supportedWhiteBalanceModes NOTIFY controlsChanged)
    Q_PROPERTY(QStringList supportedSceneModes READ supportedSceneModes NOTIFY controlsChanged)
    Q_PROPERTY(QStringList supportedColorTones READ supportedColorTones NOTIFY controlsChanged)
    Q_PROPERTY(QStringList supportedFlickerModes READ supportedFlickerModes NOTIFY controlsChanged)
    Q_PROPERTY(QVariantList supportedIsoSpeeds READ supportedIsoSpeeds NOTIFY controlsChanged)
    Q_PROPERTY(qreal minimumExposureCompensation READ minimumExposureCompensation NOTIFY controlsChanged)
    Q_PROPERTY(qreal maximumExposureCompensation READ maximumExposureCompensation NOTIFY controlsChanged)
    // The HAL's exposure-compensation-step: the only EV values it takes are whole multiples of it.
    Q_PROPERTY(qreal exposureCompensationStep READ exposureCompensationStep NOTIFY controlsChanged)
    Q_PROPERTY(qreal maximumZoom READ maximumZoom NOTIFY controlsChanged)
    Q_PROPERTY(bool hdrSupported READ hdrSupported NOTIFY controlsChanged)
    Q_PROPERTY(bool zslSupported READ zslSupported NOTIFY controlsChanged)
    Q_PROPERTY(bool focusAreasSupported READ focusAreasSupported NOTIFY controlsChanged)

    Q_PROPERTY(QString flashMode READ flashMode WRITE setFlashMode NOTIFY flashModeChanged)
    Q_PROPERTY(QString focusMode READ focusMode WRITE setFocusMode NOTIFY focusModeChanged)
    Q_PROPERTY(QString whiteBalanceMode READ whiteBalanceMode WRITE setWhiteBalanceMode NOTIFY whiteBalanceModeChanged)
    Q_PROPERTY(QString sceneMode READ sceneMode WRITE setSceneMode NOTIFY sceneModeChanged)
    Q_PROPERTY(QString colorTone READ colorTone WRITE setColorTone NOTIFY colorToneChanged)
    Q_PROPERTY(QString flickerMode READ flickerMode WRITE setFlickerMode NOTIFY flickerModeChanged)
    Q_PROPERTY(int isoSpeed READ isoSpeed WRITE setIsoSpeed NOTIFY isoSpeedChanged)
    Q_PROPERTY(qreal exposureCompensation READ exposureCompensation WRITE setExposureCompensation NOTIFY exposureCompensationChanged)
    Q_PROPERTY(qreal zoom READ zoom WRITE setZoom NOTIFY zoomChanged)
    Q_PROPERTY(bool hdrEnabled READ hdrEnabled WRITE setHdrEnabled NOTIFY hdrEnabledChanged)
    Q_PROPERTY(bool zslEnabled READ zslEnabled WRITE setZslEnabled NOTIFY zslEnabledChanged)
    Q_PROPERTY(bool torch READ torch WRITE setTorch NOTIFY torchChanged)
    Q_PROPERTY(int jpegQuality READ jpegQuality WRITE setJpegQuality NOTIFY jpegQualityChanged)

    Q_PROPERTY(FocusStatus focusStatus READ focusStatus NOTIFY focusStatusChanged)

public:
    enum FocusStatus {
        FocusIdle,
        FocusRunning,
        FocusSucceeded,
        FocusFailed,
    };
    Q_ENUM(FocusStatus)

    explicit DroidCameraFactory(QObject *parent = nullptr);
    ~DroidCameraFactory() override;

    bool available() const;

    /* How many cameras the Android HAL reports. QtMultimedia's MediaDevices
     * enumerates none of them on Halium, so a UI that wants to know whether
     * there is a second camera to switch to has nowhere else to ask. */
    int cameraCount() const;

    /* Whether gst-droid is usable in this process. Static so the QML plugin
     * can consult it at import time, before any instance exists, to decide
     * the QtMultimedia backend. */
    static bool droidPluginAvailable();

    Q_INVOKABLE QObject *createVideoSource(int cameraDevice);

    /* Full-resolution still capture through droidcamsrc's imgsrc pad -
     * Qt's own QImageCapture is hardwired to require a QCamera and never
     * fires on a native video source. */
    Q_INVOKABLE bool takePicture(const QString &filePath);

    /* Video recording through a dynamic encode branch on the viewfinder
     * tee - QMediaRecorder has the same hard QCamera dependency as
     * QImageCapture and never records from a native video source.
     * rotation is how far, clockwise, a player has to turn the recorded frames to show them
     * upright (0, 90, 180 or 270); it goes into the file as its display matrix. */
    bool recording() const;
    Q_INVOKABLE bool startRecording(const QString &filePath, int rotation = 0);
    Q_INVOKABLE void stopRecording();

    /* The HAL's cameras, without opening any: a list of
     * { index, facing: "back" | "front", orientation: degrees }. droidmedia
     * answers this from the HAL's static camera info. */
    Q_INVOKABLE QVariantList cameras() const;

    /* Focus and meter on a point of the frame (0..1 in the frame as the sensor
     * delivers it - see CameraGeometry.viewToFrame()), then run autofocus.
     * Progress is reported through focusStatus. */
    Q_INVOKABLE void focusAt(qreal x, qreal y);
    /* Back to the HAL's own choice of focus and metering area. */
    Q_INVOKABLE void resetFocus();

    bool controlsReady() const { return m_controlsReady; }
    QStringList supportedFlashModes() const { return m_supportedFlash; }
    QStringList supportedFocusModes() const { return m_supportedFocus; }
    QStringList supportedWhiteBalanceModes() const { return m_supportedWb; }
    QStringList supportedSceneModes() const { return m_supportedScene; }
    QStringList supportedColorTones() const { return m_supportedColorTone; }
    QStringList supportedFlickerModes() const { return m_supportedFlicker; }
    QVariantList supportedIsoSpeeds() const { return m_supportedIso; }
    qreal minimumExposureCompensation() const { return m_minEv; }
    qreal maximumExposureCompensation() const { return m_maxEv; }
    qreal exposureCompensationStep() const { return m_evStep; }
    /* The exposure compensation the HAL really applies for the one asked for,
     * whole steps of its exposure-compensation-step; see
     * CameraControls::appliedExposure(). */
    Q_INVOKABLE qreal appliedExposureCompensation() const;
    qreal maximumZoom() const;
    bool hdrSupported() const { return m_hdrSceneMode || m_hdrImageMode; }
    bool zslSupported() const { return m_zslImageMode; }
    bool focusAreasSupported() const { return m_maxFocusAreas > 0; }

    QString flashMode() const { return m_flashMode; }
    void setFlashMode(const QString &mode);
    QString focusMode() const { return m_focusMode; }
    void setFocusMode(const QString &mode);
    QString whiteBalanceMode() const { return m_wbMode; }
    void setWhiteBalanceMode(const QString &mode);
    QString sceneMode() const { return m_sceneMode; }
    void setSceneMode(const QString &mode);
    QString colorTone() const { return m_colorTone; }
    void setColorTone(const QString &tone);
    QString flickerMode() const { return m_flickerMode; }
    void setFlickerMode(const QString &mode);
    int isoSpeed() const { return m_isoSpeed; }
    void setIsoSpeed(int iso);
    qreal exposureCompensation() const { return m_ev; }
    void setExposureCompensation(qreal ev);
    qreal zoom() const { return m_zoom; }
    void setZoom(qreal zoom);
    bool hdrEnabled() const { return m_hdrEnabled; }
    void setHdrEnabled(bool enabled);
    bool zslEnabled() const { return m_zslEnabled; }
    void setZslEnabled(bool enabled);
    bool torch() const { return m_torch; }
    void setTorch(bool on);
    int jpegQuality() const { return m_jpegQuality; }
    void setJpegQuality(int quality);

    FocusStatus focusStatus() const { return m_focusStatus; }

signals:
    void imageSaved(const QString &filePath);
    void imageCaptureError(const QString &message);
    void recordingChanged();
    void videoSaved(const QString &filePath);
    void videoCaptureError(const QString &message);

    /* The shutter has been released: the moment to play a shutter sound or
     * flash the screen, which can be well after takePicture() when autofocus
     * runs first. */
    void captureStarted();

    void controlsChanged();
    void flashModeChanged();
    void focusModeChanged();
    void whiteBalanceModeChanged();
    void sceneModeChanged();
    void colorToneChanged();
    void flickerModeChanged();
    void isoSpeedChanged();
    void exposureCompensationChanged();
    void zoomChanged();
    void hdrEnabledChanged();
    void zslEnabledChanged();
    void torchChanged();
    void jpegQualityChanged();
    void focusStatusChanged();

private:
    /* What droidcamsrc reported once the HAL was opened, collected on the
     * thread that opened it and handed to the GUI thread in one piece. */
    struct Capabilities {
        QList<int> flash, focus, wb, scene, colorTone, flicker, iso;
        qreal minEv = 0, maxEv = 0, evStep = 0;
        QList<int> zoomRatios;
        int maxFocusAreas = 0;
        bool hdrImageMode = false;
        bool zslImageMode = false;
    };

    struct _GstElement *camera() const;
    void connectCamera(struct _GstElement *cam, unsigned generation);
    void capabilitiesReady(const Capabilities &caps, unsigned generation);
    void applyControls();
    void applyJpegQuality(struct _GstElement *cam) const;
    void applyImageMode();
    void applySceneMode();
    void setEnumProperty(const char *property, int value);
    void handleElementMessage(const QString &name, int status, unsigned generation);
    void setFocusStatus(FocusStatus status);
    void releaseShutter();
    bool autofocusBeforeCapture() const;

    void saveImage(const QByteArray &data);
    void finishRecording();
    struct _GstElement *startHwRecording(struct _GstElement *bin, const QString &filePath);
    void hwRecordingStarted(struct _GstElement *rec, const QString &filePath);
    bool startSwRecording(struct _GstElement *bin, const QString &filePath);
    void finishHwRecording(bool saved = true);

    QObject *m_videoSource = nullptr;
    QString m_pendingImagePath;

    // opaque GStreamer handles (GstElement/GstPad), kept out of the header
    void *m_recBin = nullptr;
    void *m_recTeePad = nullptr;
    bool m_hwRecording = false;
    // A stop is already under way.
    bool m_stopRequested = false;
    // A hardware recording is being set up on a worker thread (the camera reconfigures for
    // video and the encoder is created, which takes seconds), and whether a stop was asked
    // for meanwhile.
    bool m_starting = false;
    bool m_stopAfterStart = false;
    QString m_pendingVideoPath;
    // The rotation startRecording() was given, for the recording being set up.
    int m_recordingRotation = 0;
    /* Written from a GStreamer streaming thread, read from the watchdog. */
    std::atomic<unsigned> m_hwFrames{0};

    /* Bumped for every new source, so results that arrive late from the
     * previous camera's threads are recognised and dropped. */
    unsigned m_generation = 0;

    bool m_controlsReady = false;
    QStringList m_supportedFlash, m_supportedFocus, m_supportedWb,
        m_supportedScene, m_supportedColorTone, m_supportedFlicker;
    QVariantList m_supportedIso;
    qreal m_minEv = 0, m_maxEv = 0, m_evStep = 0;
    QList<int> m_zoomRatios;
    int m_maxFocusAreas = 0;
    bool m_hdrSceneMode = false;
    bool m_hdrImageMode = false;
    bool m_zslImageMode = false;

    /* What the user asked for. Kept across camera switches and applied as soon
     * as a camera's capabilities are known; a value the camera does not
     * support is left unapplied, not forgotten, so switching back to a camera
     * that has it restores it. */
    QString m_flashMode = QStringLiteral("auto");
    QString m_focusMode = QStringLiteral("continuous");
    QString m_wbMode = QStringLiteral("auto");
    QString m_sceneMode = QStringLiteral("auto");
    QString m_colorTone = QStringLiteral("none");
    QString m_flickerMode = QStringLiteral("auto");
    int m_isoSpeed = 0;
    qreal m_ev = 0;
    qreal m_zoom = 1.0;
    bool m_hdrEnabled = false;
    bool m_zslEnabled = false;
    bool m_torch = false;
    int m_jpegQuality = CameraControls::kDefaultJpegQuality;

    FocusStatus m_focusStatus = FocusIdle;
    /* A takePicture() waiting for autofocus to finish; m_focusTimeout shoots
     * anyway once the HAL has had long enough. */
    bool m_captureAfterFocus = false;
    QTimer m_focusTimeout;
    /* Which shutter release a capture timeout belongs to. */
    unsigned m_captureSerial = 0;
};

#endif // DROIDCAMERAFACTORY_H
