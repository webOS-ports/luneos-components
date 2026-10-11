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

#ifndef CAMERACONTROLS_H
#define CAMERACONTROLS_H

#include <QList>
#include <QPointF>
#include <QRect>
#include <QSize>
#include <QSizeF>
#include <QString>
#include <QStringList>

/*
 * The parts of driving a camera that are plain arithmetic and table lookups,
 * kept away from GStreamer and the HAL so they can be unit tested on the build
 * host. DroidCameraFactory and the QML viewfinder are the only callers.
 */
namespace CameraControls {

/*
 * The names QML sees for the GstPhotography modes. They are the Android camera
 * parameter values gst-droid itself maps each mode to (gstdroidcamsrcphotography.c),
 * so what the HAL reports and what the UI offers line up one to one. Each kind
 * has its own table; a value that is not in it maps to an empty name / -1.
 */
enum class ModeKind {
    Flash,
    Focus,
    WhiteBalance,
    Scene,
    ColorTone,
    Flicker,
};

QString modeName(ModeKind kind, int value);
int modeValue(ModeKind kind, const QString &name);

/* The names for a list of mode values, in order, without duplicates and without
 * values that have no name (gst-droid lists both continuous focus modes, which
 * share the name "continuous"). */
QStringList modeNames(ModeKind kind, const QList<int> &values);

/*
 * Android expresses zoom as an index into "zoom-ratios", a comma separated list
 * of magnifications in percent ("100,102,104,...,800"). These turn that list
 * into numbers and pick the index for a wanted magnification: the largest ratio
 * not above it, so a pinch never overshoots what was asked for. An empty or
 * unparseable list gives an empty QList, and with no ratios the index is 0.
 */
QList<int> parseZoomRatios(const QString &ratios);
int zoomIndexForRatio(const QList<int> &ratiosPercent, qreal ratio);
qreal maximumZoomRatio(const QList<int> &ratiosPercent);

/*
 * The exposure compensation, in EV, that the camera really applies when asked
 * for `ev`. Android takes it as a whole number of steps of `step` EV;
 * gst-droid clamps `ev` to [minEv, maxEv] and divides by the step in single
 * precision, dropping the fraction, and this does the same. Some HALs (the
 * Q25's) write that step count into the photo's EXIF as if it were EV, so the
 * camera app writes this value instead. 0 when the step is unknown, as
 * gst-droid then applies nothing.
 */
qreal appliedExposure(qreal ev, qreal minEv, qreal maxEv, qreal step);

/*
 * A JPEG quality droidcamsrc takes: its jpeg-quality property runs from 10 to
 * 100. kDefaultJpegQuality is what it uses when nobody sets it.
 */
constexpr int kDefaultJpegQuality = 90;
int jpegQuality(int wanted);

/*
 * The focus/metering rectangle for a tap, in frame pixels: a square whose side
 * is boxFraction of the frame's shorter side, centred on the normalised point
 * and pushed back inside the frame when the point is near an edge. Returns an
 * empty rect for an empty frame or a point outside [0,1]x[0,1].
 */
QRect focusRegion(const QPointF &normalisedPoint, const QSize &frame, qreal boxFraction = 0.1);

/*
 * Where a point tapped on the viewfinder lies in the camera frame, as 0..1
 * coordinates of the frame as the sensor delivers it.
 *
 * It undoes, in reverse order, what the viewfinder does to the frame:
 *   1. VideoOutput turns the frame by `rotation` degrees counter-clockwise
 *      (a multiple of 90; this is how the app sets VideoOutput.orientation),
 *   2. mirrors it left to right when `mirrored`,
 *   3. fits it into the view keeping its aspect ratio (letterboxed),
 *   4. scales the whole view by `viewZoom` about its centre (digital zoom).
 *
 * frameSize is the frame's size before rotation. Returns (-1, -1) when the
 * point falls outside the picture (on a letterbox bar) or a size is empty.
 */
QPointF viewToFrame(const QPointF &viewPoint, const QSizeF &viewSize,
                    const QSizeF &frameSize, int rotation, bool mirrored,
                    qreal viewZoom = 1.0);

} // namespace CameraControls

#endif // CAMERACONTROLS_H
