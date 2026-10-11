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

#include "barcodescanner.h"
#include "barcodedecoder.h"

#include <QCoreApplication>
#include <QImage>
#include <QThreadPool>
#include <QVideoFrame>
#include <QVideoSink>

/* Codes are found reliably at this size, and a phone decodes it in tens of
 * milliseconds; a full 12 MP frame would take a second. */
static const int kMaxDecodeSide = 1280;
/* How long the same code stays quiet after it has been reported. */
static const int kRepeatQuietMs = 3000;
/* How long a linear code seen once waits for its second sighting: a few scans
 * at the default interval, and much less than it takes to aim at another code. */
static const int kConfirmWithinMs = 1500;

BarcodeScanner::BarcodeScanner(QObject *parent)
    : QObject(parent)
    , m_busy(std::make_shared<std::atomic<bool>>(false))
{
}

BarcodeScanner::~BarcodeScanner() = default;

QVideoSink *BarcodeScanner::videoSink() const
{
    return m_sink.data();
}

void BarcodeScanner::setVideoSink(QVideoSink *sink)
{
    if (m_sink == sink)
        return;
    if (m_sink)
        disconnect(m_sink, nullptr, this, nullptr);
    m_sink = sink;
    if (m_sink)
        connect(m_sink, &QVideoSink::videoFrameChanged, this, &BarcodeScanner::frameArrived);
    emit videoSinkChanged();
}

void BarcodeScanner::setActive(bool active)
{
    if (m_active == active)
        return;
    m_active = active;
    m_lastText.clear();
    m_unconfirmedText.clear();
    emit activeChanged();
}

void BarcodeScanner::setInterval(int ms)
{
    ms = std::max(ms, 0);
    if (m_interval == ms)
        return;
    m_interval = ms;
    emit intervalChanged();
}

/* The luminance of a frame, whatever its layout. */
static BarcodeDecoder::LumaImage lumaOf(const QVideoFrame &source)
{
    using namespace BarcodeDecoder;
    QVideoFrame frame(source);
    const int w = frame.width();
    const int h = frame.height();
    const int step = stepFor(w, h, kMaxDecodeSide);

    switch (frame.pixelFormat()) {
    case QVideoFrameFormat::Format_YUV420P:
    case QVideoFrameFormat::Format_YUV422P:
    case QVideoFrameFormat::Format_YV12:
    case QVideoFrameFormat::Format_NV12:
    case QVideoFrameFormat::Format_NV21:
    case QVideoFrameFormat::Format_IMC1:
    case QVideoFrameFormat::Format_IMC2:
    case QVideoFrameFormat::Format_IMC3:
    case QVideoFrameFormat::Format_IMC4:
    case QVideoFrameFormat::Format_Y8:
    case QVideoFrameFormat::Format_P010:
    case QVideoFrameFormat::Format_P016:
    case QVideoFrameFormat::Format_YUYV:
    case QVideoFrameFormat::Format_UYVY: {
        if (!frame.map(QVideoFrame::ReadOnly))
            return LumaImage();
        int pixelStride = 1, offset = 0;
        switch (frame.pixelFormat()) {
        case QVideoFrameFormat::Format_YUYV: pixelStride = 2; break;
        /* UYVY has its Y in the odd bytes. P010 and P016 have 16-bit
         * little-endian samples with the value in the top bits, so the high
         * byte is the 8-bit sample. (YUV420P10 keeps its 10 bits at the bottom
         * and goes through QImage instead.) */
        case QVideoFrameFormat::Format_UYVY:
        case QVideoFrameFormat::Format_P010:
        case QVideoFrameFormat::Format_P016: pixelStride = 2; offset = 1; break;
        default: break;
        }
        LumaImage image = extractLuma(frame.bits(0), w, h, frame.bytesPerLine(0),
                                      pixelStride, offset, step);
        frame.unmap();
        return image;
    }
    default: {
        // RGB and anything else: let Qt convert it.
        QImage grey = frame.toImage().convertToFormat(QImage::Format_Grayscale8);
        if (grey.isNull())
            return LumaImage();
        if (step > 1)
            grey = grey.scaled(grey.width() / step, grey.height() / step);
        return extractLuma(grey.constBits(), grey.width(), grey.height(),
                           int(grey.bytesPerLine()));
    }
    }
}

void BarcodeScanner::frameArrived(const QVideoFrame &frame)
{
    if (!m_active || !frame.isValid() || m_busy->load())
        return;
    if (m_sinceLastScan.isValid() && m_sinceLastScan.elapsed() < m_interval)
        return;
    m_sinceLastScan.start();

    /* The copy happens here, on the GUI thread, while the frame is certainly
     * alive; only plain bytes go to the worker. */
    BarcodeDecoder::LumaImage image = lumaOf(frame);
    if (!image.isValid())
        return;

    m_busy->store(true);
    auto busy = m_busy;
    QPointer<BarcodeScanner> guard(this);
    QThreadPool::globalInstance()->start([image, busy, guard] {
        const QList<BarcodeDecoder::Symbol> symbols = BarcodeDecoder::decode(image);
        busy->store(false);
        for (const auto &symbol : symbols) {
            QMetaObject::invokeMethod(QCoreApplication::instance(), [guard, symbol] {
                if (guard)
                    guard->reportResult(symbol.text, symbol.format);
            }, Qt::QueuedConnection);
        }
    });
}

void BarcodeScanner::reportResult(const QString &text, const QString &format)
{
    if (!m_active || text.isEmpty())
        return;
    if (BarcodeDecoder::needsConfirmation(format) && text != m_lastText) {
        const bool confirmed = text == m_unconfirmedText && m_sinceUnconfirmed.isValid()
            && m_sinceUnconfirmed.elapsed() < kConfirmWithinMs;
        if (!confirmed) {
            m_unconfirmedText = text;
            m_sinceUnconfirmed.start();
            return;
        }
    }
    m_unconfirmedText.clear();
    if (text == m_lastText && m_sinceLastText.isValid() && m_sinceLastText.elapsed() < kRepeatQuietMs) {
        m_sinceLastText.start();
        return;
    }
    m_lastText = text;
    m_sinceLastText.start();
    emit decoded(text, format);
}
