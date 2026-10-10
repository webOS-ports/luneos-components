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

#ifndef BARCODESCANNER_H
#define BARCODESCANNER_H

#include <QElapsedTimer>
#include <QObject>
#include <QPointer>
#include <QString>
#include <QVideoSink>

#include <atomic>
#include <memory>

class QVideoFrame;

/*
 * Reads QR codes and barcodes off a viewfinder: point videoSink at the
 * VideoOutput's sink and decoded() fires for each code that comes into view.
 *
 * It looks at the frames the viewfinder is shown anyway, so it works the same
 * whichever camera stack feeds the VideoOutput (gst-droid or libcamera), and
 * costs nothing while inactive. Frames are sampled every `interval` ms and
 * decoded with zbar on a worker thread; while a decode runs newer frames are
 * dropped, never queued. The same code is reported once, not on every frame
 * it stays in view.
 */
class BarcodeScanner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVideoSink *videoSink READ videoSink WRITE setVideoSink NOTIFY videoSinkChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(int interval READ interval WRITE setInterval NOTIFY intervalChanged)

public:
    explicit BarcodeScanner(QObject *parent = nullptr);
    ~BarcodeScanner() override;

    QVideoSink *videoSink() const;
    void setVideoSink(QVideoSink *sink);
    bool active() const { return m_active; }
    void setActive(bool active);
    int interval() const { return m_interval; }
    void setInterval(int ms);

signals:
    void decoded(const QString &text, const QString &format);
    void videoSinkChanged();
    void activeChanged();
    void intervalChanged();

private:
    void frameArrived(const QVideoFrame &frame);
    void reportResult(const QString &text, const QString &format);

    QPointer<QVideoSink> m_sink;
    bool m_active = false;
    int m_interval = 250;
    QElapsedTimer m_sinceLastScan;
    /* Shared with the worker, which may outlive the scanner by one decode. */
    std::shared_ptr<std::atomic<bool>> m_busy;

    QString m_lastText;
    QElapsedTimer m_sinceLastText;
};

#endif // BARCODESCANNER_H
