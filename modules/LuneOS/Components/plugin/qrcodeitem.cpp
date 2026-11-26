/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

#include "qrcodeitem.h"
#include "qrencoder.h"

#include <QPainter>
#include <QtMath>

QrCodeItem::QrCodeItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(false);
    setFillColor(Qt::transparent);
}

void QrCodeItem::setText(const QString &text)
{
    if (m_text == text)
        return;
    m_text = text;
    encode();
    emit textChanged();
}

void QrCodeItem::setErrorCorrection(ErrorCorrection level)
{
    if (m_errorCorrection == level)
        return;
    m_errorCorrection = level;
    encode();
    emit errorCorrectionChanged();
}

void QrCodeItem::setColor(const QColor &color)
{
    if (m_color == color)
        return;
    m_color = color;
    colourise();
    update();
    emit colorChanged();
}

void QrCodeItem::setBackgroundColor(const QColor &color)
{
    if (m_backgroundColor == color)
        return;
    m_backgroundColor = color;
    colourise();
    update();
    emit backgroundColorChanged();
}

void QrCodeItem::setQuietZone(int modules)
{
    modules = qBound(0, modules, 16);
    if (m_quietZone == modules)
        return;
    m_quietZone = modules;
    encode();
    emit quietZoneChanged();
}

void QrCodeItem::encode()
{
    QrEncoder::Level level = QrEncoder::Level::Medium;
    switch (m_errorCorrection) {
    case Low: level = QrEncoder::Level::Low; break;
    case Medium: level = QrEncoder::Level::Medium; break;
    case Quartile: level = QrEncoder::Level::Quartile; break;
    case High: level = QrEncoder::Level::High; break;
    }

    const QrEncoder::Result result = QrEncoder::encode(m_text.toUtf8(), level, m_quietZone);

    m_code = result.image;
    m_moduleCount = result.modules;
    switch (result.error) {
    case QrEncoder::Error::None:
    case QrEncoder::Error::Empty: m_error.clear(); break;
    case QrEncoder::Error::TooLong: m_error = QStringLiteral("tooLong"); break;
    case QrEncoder::Error::Unavailable: m_error = QStringLiteral("unavailable"); break;
    case QrEncoder::Error::Failed: m_error = QStringLiteral("failed"); break;
    }
    /* Why, but never what: the text may be a passphrase. */
    if (!m_error.isEmpty())
        qWarning("QrCode: no code for a text of %lld bytes (%s)",
                 static_cast<long long>(m_text.toUtf8().size()), qPrintable(m_error));

    const int side = m_code.isNull() ? 0 : m_code.width();
    setImplicitWidth(side * 4);
    setImplicitHeight(side * 4);

    colourise();
    update();
    emit codeChanged();
}

void QrCodeItem::colourise()
{
    if (m_code.isNull()) {
        m_coloured = QImage();
        return;
    }
    QImage coloured(m_code.size(), QImage::Format_ARGB32_Premultiplied);
    if (coloured.isNull()) {
        m_coloured = QImage();
        return;
    }
    const QRgb dark = m_color.rgba();
    const QRgb light = m_backgroundColor.rgba();
    const QRgb darkPremultiplied = qPremultiply(dark);
    const QRgb lightPremultiplied = qPremultiply(light);
    for (int y = 0; y < m_code.height(); ++y) {
        const uchar *src = m_code.constScanLine(y);
        QRgb *dst = reinterpret_cast<QRgb *>(coloured.scanLine(y));
        for (int x = 0; x < m_code.width(); ++x)
            dst[x] = src[x] ? lightPremultiplied : darkPremultiplied;
    }
    m_coloured = coloured;
}

QRectF QrCodeItem::codeRect(const QSizeF &size, int side)
{
    if (side <= 0 || size.width() <= 0 || size.height() <= 0)
        return QRectF();
    const qreal available = qMin(size.width(), size.height());
    /* Whole pixels per module when there is room for one; a fraction only when there is not. */
    qreal module = qFloor(available / side);
    if (module < 1)
        module = available / side;
    const qreal extent = module * side;
    return QRectF(qFloor((size.width() - extent) / 2), qFloor((size.height() - extent) / 2),
                  extent, extent);
}

void QrCodeItem::paint(QPainter *painter)
{
    if (m_coloured.isNull())
        return;
    const QRectF target = codeRect(QSizeF(width(), height()), m_coloured.width());
    if (target.isEmpty())
        return;
    painter->setRenderHint(QPainter::SmoothPixmapTransform, false);
    painter->setRenderHint(QPainter::Antialiasing, false);
    painter->drawImage(target, m_coloured);
}
