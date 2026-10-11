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

#include "cameracontrols.h"

#include <gst/interfaces/photography.h>

#include <algorithm>
#include <cmath>

namespace CameraControls {

namespace {

struct ModeEntry {
    int value;
    const char *name;
};

/* Copied from gst-droid's own tables (gstdroidcamsrcphotography.c), which
 * decide the Android value each GstPhotography mode is sent as. */
const ModeEntry kFlash[] = {
    { GST_PHOTOGRAPHY_FLASH_MODE_AUTO, "auto" },
    { GST_PHOTOGRAPHY_FLASH_MODE_OFF, "off" },
    { GST_PHOTOGRAPHY_FLASH_MODE_ON, "on" },
    { GST_PHOTOGRAPHY_FLASH_MODE_RED_EYE, "red-eye" },
};

const ModeEntry kFocus[] = {
    { GST_PHOTOGRAPHY_FOCUS_MODE_AUTO, "auto" },
    { GST_PHOTOGRAPHY_FOCUS_MODE_MACRO, "macro" },
    { GST_PHOTOGRAPHY_FOCUS_MODE_INFINITY, "infinity" },
    { GST_PHOTOGRAPHY_FOCUS_MODE_HYPERFOCAL, "fixed" },
    { GST_PHOTOGRAPHY_FOCUS_MODE_EXTENDED, "edof" },
    { GST_PHOTOGRAPHY_FOCUS_MODE_CONTINUOUS_NORMAL, "continuous" },
    { GST_PHOTOGRAPHY_FOCUS_MODE_CONTINUOUS_EXTENDED, "continuous" },
    { GST_PHOTOGRAPHY_FOCUS_MODE_MANUAL, "manual" },
};

const ModeEntry kWhiteBalance[] = {
    { GST_PHOTOGRAPHY_WB_MODE_AUTO, "auto" },
    { GST_PHOTOGRAPHY_WB_MODE_DAYLIGHT, "daylight" },
    { GST_PHOTOGRAPHY_WB_MODE_CLOUDY, "cloudy-daylight" },
    { GST_PHOTOGRAPHY_WB_MODE_SUNSET, "twilight" },
    { GST_PHOTOGRAPHY_WB_MODE_TUNGSTEN, "incandescent" },
    { GST_PHOTOGRAPHY_WB_MODE_FLUORESCENT, "fluorescent" },
    { GST_PHOTOGRAPHY_WB_MODE_MANUAL, "manual" },
    { GST_PHOTOGRAPHY_WB_MODE_WARM_FLUORESCENT, "warm-fluorescent" },
    { GST_PHOTOGRAPHY_WB_MODE_SHADE, "shade" },
};

const ModeEntry kScene[] = {
    { GST_PHOTOGRAPHY_SCENE_MODE_MANUAL, "auto" },
    { GST_PHOTOGRAPHY_SCENE_MODE_AUTO, "asd" },
    { GST_PHOTOGRAPHY_SCENE_MODE_PORTRAIT, "portrait" },
    { GST_PHOTOGRAPHY_SCENE_MODE_LANDSCAPE, "landscape" },
    { GST_PHOTOGRAPHY_SCENE_MODE_SPORT, "sports" },
    { GST_PHOTOGRAPHY_SCENE_MODE_NIGHT, "night" },
    { GST_PHOTOGRAPHY_SCENE_MODE_ACTION, "action" },
    { GST_PHOTOGRAPHY_SCENE_MODE_NIGHT_PORTRAIT, "night-portrait" },
    { GST_PHOTOGRAPHY_SCENE_MODE_THEATRE, "theatre" },
    { GST_PHOTOGRAPHY_SCENE_MODE_BEACH, "beach" },
    { GST_PHOTOGRAPHY_SCENE_MODE_SNOW, "snow" },
    { GST_PHOTOGRAPHY_SCENE_MODE_SUNSET, "sunset" },
    { GST_PHOTOGRAPHY_SCENE_MODE_STEADY_PHOTO, "steadyphoto" },
    { GST_PHOTOGRAPHY_SCENE_MODE_FIREWORKS, "fireworks" },
    { GST_PHOTOGRAPHY_SCENE_MODE_PARTY, "party" },
    { GST_PHOTOGRAPHY_SCENE_MODE_CANDLELIGHT, "candlelight" },
    { GST_PHOTOGRAPHY_SCENE_MODE_BARCODE, "barcode" },
    { GST_PHOTOGRAPHY_SCENE_MODE_BACKLIGHT, "backlight" },
    { GST_PHOTOGRAPHY_SCENE_MODE_FLOWERS, "flowers" },
    { GST_PHOTOGRAPHY_SCENE_MODE_AR, "AR" },
    { GST_PHOTOGRAPHY_SCENE_MODE_HDR, "hdr" },
};

const ModeEntry kColorTone[] = {
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_NORMAL, "none" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_SEPIA, "sepia" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_NEGATIVE, "negative" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_GRAYSCALE, "mono" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_VIVID, "vivid" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_SOLARIZE, "solarize" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_SKY_BLUE, "still-sky-blue" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_GRASS_GREEN, "still-grass-green" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_SKIN_WHITEN, "still-skin-whiten-medium" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_POSTERIZE, "posterize" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_WHITEBOARD, "whiteboard" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_BLACKBOARD, "blackboard" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_AQUA, "aqua" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_EMBOSS, "emboss" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_SKETCH, "sketch" },
    { GST_PHOTOGRAPHY_COLOR_TONE_MODE_NEON, "neon" },
};

const ModeEntry kFlicker[] = {
    { GST_PHOTOGRAPHY_FLICKER_REDUCTION_OFF, "off" },
    { GST_PHOTOGRAPHY_FLICKER_REDUCTION_50HZ, "50hz" },
    { GST_PHOTOGRAPHY_FLICKER_REDUCTION_60HZ, "60hz" },
    { GST_PHOTOGRAPHY_FLICKER_REDUCTION_AUTO, "auto" },
};

struct Table {
    const ModeEntry *begin;
    const ModeEntry *end;
};

template <size_t N>
Table makeTable(const ModeEntry (&entries)[N])
{
    return Table{ entries, entries + N };
}

Table tableFor(ModeKind kind)
{
    switch (kind) {
    case ModeKind::Flash:        return makeTable(kFlash);
    case ModeKind::Focus:        return makeTable(kFocus);
    case ModeKind::WhiteBalance: return makeTable(kWhiteBalance);
    case ModeKind::Scene:        return makeTable(kScene);
    case ModeKind::ColorTone:    return makeTable(kColorTone);
    case ModeKind::Flicker:      return makeTable(kFlicker);
    }
    return Table{ nullptr, nullptr };
}

} // namespace

QString modeName(ModeKind kind, int value)
{
    const Table t = tableFor(kind);
    for (const ModeEntry *e = t.begin; e != t.end; ++e) {
        if (e->value == value)
            return QString::fromLatin1(e->name);
    }
    return QString();
}

int modeValue(ModeKind kind, const QString &name)
{
    const Table t = tableFor(kind);
    for (const ModeEntry *e = t.begin; e != t.end; ++e) {
        if (name == QLatin1String(e->name))
            return e->value;
    }
    return -1;
}

QStringList modeNames(ModeKind kind, const QList<int> &values)
{
    QStringList names;
    for (int value : values) {
        const QString name = modeName(kind, value);
        if (!name.isEmpty() && !names.contains(name))
            names.append(name);
    }
    return names;
}

QList<int> parseZoomRatios(const QString &ratios)
{
    QList<int> result;
    const QStringList parts = ratios.split(QLatin1Char(','), Qt::SkipEmptyParts);
    for (const QString &part : parts) {
        bool ok = false;
        const int value = part.trimmed().toInt(&ok);
        if (!ok || value <= 0)
            return QList<int>();
        result.append(value);
    }
    return result;
}

int zoomIndexForRatio(const QList<int> &ratiosPercent, qreal ratio)
{
    /* A hair of tolerance so 2.0 picks a "200" entry despite 2.0 * 100 coming
     * out as 199.99999 after a pinch's arithmetic. */
    const qreal wanted = ratio * 100.0 + 0.001;
    int best = 0;
    int bestRatio = -1;
    for (int i = 0; i < ratiosPercent.size(); ++i) {
        const int r = ratiosPercent.at(i);
        if (r <= wanted && r > bestRatio) {
            best = i;
            bestRatio = r;
        }
    }
    return best;
}

qreal maximumZoomRatio(const QList<int> &ratiosPercent)
{
    if (ratiosPercent.isEmpty())
        return 1.0;
    return *std::max_element(ratiosPercent.cbegin(), ratiosPercent.cend()) / 100.0;
}

qreal appliedExposure(qreal ev, qreal minEv, qreal maxEv, qreal step)
{
    if (!(step > 0) || !std::isfinite(ev))
        return 0;
    const float clamped = std::clamp(static_cast<float>(ev), static_cast<float>(std::min(minEv, maxEv)),
                                     static_cast<float>(std::max(minEv, maxEv)));
    const int steps = static_cast<int>(clamped / static_cast<float>(step));
    return static_cast<qreal>(static_cast<float>(steps) * static_cast<float>(step));
}

QRect focusRegion(const QPointF &normalisedPoint, const QSize &frame, qreal boxFraction)
{
    if (frame.isEmpty()
        || normalisedPoint.x() < 0.0 || normalisedPoint.x() > 1.0
        || normalisedPoint.y() < 0.0 || normalisedPoint.y() > 1.0)
        return QRect();

    const int shorter = std::min(frame.width(), frame.height());
    const int side = std::clamp(static_cast<int>(std::lround(shorter * boxFraction)), 1, shorter);

    // The pixel the point falls in; 1.0 is the last one, not one past it.
    const int cx = std::min(static_cast<int>(std::floor(normalisedPoint.x() * frame.width())),
                            frame.width() - 1);
    const int cy = std::min(static_cast<int>(std::floor(normalisedPoint.y() * frame.height())),
                            frame.height() - 1);
    const int left = std::clamp(cx - side / 2, 0, frame.width() - side);
    const int top = std::clamp(cy - side / 2, 0, frame.height() - side);

    return QRect(left, top, side, side);
}

QPointF viewToFrame(const QPointF &viewPoint, const QSizeF &viewSize,
                    const QSizeF &frameSize, int rotation, bool mirrored,
                    qreal viewZoom)
{
    const QPointF invalid(-1.0, -1.0);
    if (viewSize.isEmpty() || frameSize.isEmpty() || viewZoom <= 0.0)
        return invalid;

    rotation = ((rotation % 360) + 360) % 360;
    if (rotation % 90)
        return invalid;

    // 4. The zoom scales the view about its centre.
    const QPointF centre(viewSize.width() / 2.0, viewSize.height() / 2.0);
    const QPointF p = centre + (viewPoint - centre) / viewZoom;

    // 3. The (rotated) frame is fitted into the view, letterboxed.
    const QSizeF shown = (rotation % 180) ? frameSize.transposed() : frameSize;
    const qreal scale = std::min(viewSize.width() / shown.width(),
                                 viewSize.height() / shown.height());
    const qreal w = shown.width() * scale;
    const qreal h = shown.height() * scale;
    qreal u = (p.x() - (viewSize.width() - w) / 2.0) / w;
    qreal v = (p.y() - (viewSize.height() - h) / 2.0) / h;
    if (u < 0.0 || u > 1.0 || v < 0.0 || v > 1.0)
        return invalid;

    // 2. Mirroring is applied to the picture as shown.
    if (mirrored)
        u = 1.0 - u;

    // 1. The frame was turned counter-clockwise by `rotation`; turn back.
    switch (rotation) {
    case 90:  return QPointF(1.0 - v, u);
    case 180: return QPointF(1.0 - u, 1.0 - v);
    case 270: return QPointF(v, 1.0 - u);
    default:  return QPointF(u, v);
    }
}

} // namespace CameraControls
