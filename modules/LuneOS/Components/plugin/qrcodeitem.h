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

#ifndef QRCODEITEM_H
#define QRCODEITEM_H

#include <QColor>
#include <QImage>
#include <QQuickPaintedItem>
#include <QString>

/*
 * A QR code of text, as LuneOS.Components.QrCode:
 *
 *     QrCode {
 *         width: Units.gu(24); height: width
 *         text: WifiQrCode.compose(ssid, "psk", passphrase)
 *     }
 *
 * Drawn square, as large as fits and centred, every module a whole number of
 * pixels when there is room for that: a code whose modules blur into each
 * other at the edges is one a camera struggles with. The quiet zone is part
 * of what is drawn, so the item needs no margin of its own; keep the colours
 * dark on light, which is the only way round every reader takes.
 *
 * The text never goes into a URL, an image cache or the log, which matters
 * when it holds a Wi-Fi passphrase; an image provider would have put it in
 * all three.
 */
class QrCodeItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(ErrorCorrection errorCorrection READ errorCorrection WRITE setErrorCorrection NOTIFY errorCorrectionChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor backgroundColor READ backgroundColor WRITE setBackgroundColor NOTIFY backgroundColorChanged)
    Q_PROPERTY(int quietZone READ quietZone WRITE setQuietZone NOTIFY quietZoneChanged)
    /* True when there is a code to show; false for no text, too much, or a build without libqrencode. */
    Q_PROPERTY(bool valid READ valid NOTIFY codeChanged)
    /* "", "tooLong", "unavailable" or "failed". */
    Q_PROPERTY(QString error READ error NOTIFY codeChanged)
    /* Modules along a side, without the quiet zone; 0 when not valid. */
    Q_PROPERTY(int moduleCount READ moduleCount NOTIFY codeChanged)

public:
    enum ErrorCorrection { Low, Medium, Quartile, High };
    Q_ENUM(ErrorCorrection)

    explicit QrCodeItem(QQuickItem *parent = nullptr);

    QString text() const { return m_text; }
    void setText(const QString &text);
    ErrorCorrection errorCorrection() const { return m_errorCorrection; }
    void setErrorCorrection(ErrorCorrection level);
    QColor color() const { return m_color; }
    void setColor(const QColor &color);
    QColor backgroundColor() const { return m_backgroundColor; }
    void setBackgroundColor(const QColor &color);
    int quietZone() const { return m_quietZone; }
    void setQuietZone(int modules);

    bool valid() const { return !m_code.isNull(); }
    QString error() const { return m_error; }
    int moduleCount() const { return m_moduleCount; }

    void paint(QPainter *painter) override;

    /* Where paint() puts a code side modules wide, in an item of size; for the tests. */
    static QRectF codeRect(const QSizeF &size, int side);

signals:
    void textChanged();
    void errorCorrectionChanged();
    void colorChanged();
    void backgroundColorChanged();
    void quietZoneChanged();
    void codeChanged();

private:
    void encode();
    void colourise();

    QString m_text;
    ErrorCorrection m_errorCorrection = Medium;
    QColor m_color = Qt::black;
    QColor m_backgroundColor = Qt::white;
    int m_quietZone = 4;

    /* One pixel per module, as QrEncoder drew it, and in our colours. */
    QImage m_code;
    QImage m_coloured;
    QString m_error;
    int m_moduleCount = 0;
};

#endif // QRCODEITEM_H
