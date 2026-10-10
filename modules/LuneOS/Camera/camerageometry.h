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

#ifndef CAMERAGEOMETRY_H
#define CAMERAGEOMETRY_H

#include <QObject>
#include <QPointF>
#include <QSizeF>

#include "cameracontrols.h"

/*
 * Viewfinder geometry for QML; see CameraControls::viewToFrame() for what each
 * argument means. A tap on a rotated, mirrored, letterboxed and zoomed
 * VideoOutput becomes a point of the camera frame, ready for
 * DroidCameraFactory.focusAt().
 */
class CameraGeometry : public QObject
{
    Q_OBJECT

public:
    explicit CameraGeometry(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE QPointF viewToFrame(const QPointF &viewPoint, const QSizeF &viewSize,
                                    const QSizeF &frameSize, int rotation, bool mirrored,
                                    qreal viewZoom = 1.0) const
    {
        return CameraControls::viewToFrame(viewPoint, viewSize, frameSize, rotation,
                                           mirrored, viewZoom);
    }
};

#endif // CAMERAGEOMETRY_H
