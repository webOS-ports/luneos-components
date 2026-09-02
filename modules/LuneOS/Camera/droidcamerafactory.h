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

/*
 * On Halium devices the cameras are not visible to QtMultimedia's device
 * enumeration: they sit behind the Android camera HAL, reached through
 * gst-droid's droidcamsrc element. This factory hands QML a
 * QGStreamerVideoSource wrapping a droidcamsrc bin, to be assigned to
 * CaptureSession.nativeVideoSource (Qt >= 6.12).
 */
class DroidCameraFactory : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)

public:
    explicit DroidCameraFactory(QObject *parent = nullptr);

    bool available() const;

    Q_INVOKABLE QObject *createVideoSource(int cameraDevice);

    /* Full-resolution still capture through droidcamsrc's imgsrc pad -
     * Qt's own QImageCapture is hardwired to require a QCamera and never
     * fires on a native video source. */
    Q_INVOKABLE bool takePicture(const QString &filePath);

signals:
    void imageSaved(const QString &filePath);
    void imageCaptureError(const QString &message);

private:
    void saveImage(const QByteArray &data);

    QObject *m_videoSource = nullptr;
    QString m_pendingImagePath;
};

#endif // DROIDCAMERAFACTORY_H
