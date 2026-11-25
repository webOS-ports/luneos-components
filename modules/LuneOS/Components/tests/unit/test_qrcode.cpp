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

#include <gtest/gtest.h>

#include <QPainter>
#include <QSignalSpy>

#include <zbar.h>

#include "qrcodeitem.h"
#include "qrencoder.h"
#include "wifiqrcode.h"

/*
 * What QrEncoder and QrCode draw is read back with zbar, the decoder
 * LuneOS.Camera's BarcodeScanner uses: a code is only right if a camera can
 * read it.
 */

/* zbar.h puts its C API in namespace zbar when compiled as C++. */
using namespace zbar;

namespace {

/* Every QR code zbar finds in a picture, as UTF-8 text. */
QStringList readCodes(const QImage &picture)
{
    const QImage grey = picture.convertToFormat(QImage::Format_Grayscale8);
    const int w = grey.width();
    const int h = grey.height();
    QByteArray packed(qsizetype(w) * h, '\0');
    for (int y = 0; y < h; ++y)
        memcpy(packed.data() + qsizetype(y) * w, grey.constScanLine(y), size_t(w));

    zbar_image_scanner_t *scanner = zbar_image_scanner_create();
    zbar_image_scanner_set_config(scanner, ZBAR_NONE, ZBAR_CFG_ENABLE, 0);
    zbar_image_scanner_set_config(scanner, ZBAR_QRCODE, ZBAR_CFG_ENABLE, 1);
    zbar_image_t *image = zbar_image_create();
    zbar_image_set_format(image, zbar_fourcc('Y', '8', '0', '0'));
    zbar_image_set_size(image, unsigned(w), unsigned(h));
    zbar_image_set_data(image, packed.constData(), size_t(packed.size()), nullptr);

    QStringList found;
    if (zbar_scan_image(scanner, image) > 0) {
        for (const zbar_symbol_t *s = zbar_image_first_symbol(image); s; s = zbar_symbol_next(s))
            found << QString::fromUtf8(zbar_symbol_get_data(s), int(zbar_symbol_get_data_length(s)));
    }
    zbar_image_destroy(image);
    zbar_image_scanner_destroy(scanner);
    return found;
}

/* A code at one pixel per module is too small for any reader; blow it up without blurring. */
QImage magnified(const QImage &code, int factor = 6)
{
    return code.scaled(code.size() * factor, Qt::IgnoreAspectRatio, Qt::FastTransformation);
}

} // namespace

TEST(QrEncoder, Available)
{
    EXPECT_TRUE(QrEncoder::available());
}

TEST(QrEncoder, ReadsBackWhatWasEncoded)
{
    const QList<QByteArray> texts = {
        QByteArrayLiteral("HELLO"),
        QByteArrayLiteral("WIFI:S:Home;T:WPA;P:secret123;;"),
        QByteArrayLiteral("WIFI:S:a\\;b;T:WPA;P:p\\:w\\,d\\\\1234;H:true;;"),
        QByteArrayLiteral("https://www.webos-ports.org/wiki/Main_Page"),
        QByteArray(300, 'x'),
    };
    for (const QByteArray &text : texts) {
        const QrEncoder::Result r = QrEncoder::encode(text);
        ASSERT_EQ(r.error, QrEncoder::Error::None) << text.constData();
        EXPECT_EQ(readCodes(magnified(r.image)), QStringList{QString::fromUtf8(text)}) << text.constData();
    }
}

TEST(QrEncoder, EveryLevelReads)
{
    const QByteArray text = QByteArrayLiteral("WIFI:S:Home;T:WPA;P:secret123;;");
    int previous = 0;
    for (QrEncoder::Level level : {QrEncoder::Level::Low, QrEncoder::Level::Medium,
                                   QrEncoder::Level::Quartile, QrEncoder::Level::High}) {
        const QrEncoder::Result r = QrEncoder::encode(text, level);
        ASSERT_EQ(r.error, QrEncoder::Error::None);
        /* More correction takes more room, never less. */
        EXPECT_GE(r.modules, previous);
        previous = r.modules;
        EXPECT_EQ(readCodes(magnified(r.image)), QStringList{QString::fromUtf8(text)});
    }
}

TEST(QrEncoder, SmallestVersionThatHolds)
{
    /* Version 1 is 21 modules; "HELLO" in byte mode fits it at any level but High... */
    EXPECT_EQ(QrEncoder::encode("HELLO", QrEncoder::Level::Low).modules, 21);
    /* ...and version 40, 177 modules, holds 2953 bytes at Low. */
    EXPECT_EQ(QrEncoder::encode(QByteArray(2953, 'a'), QrEncoder::Level::Low).modules, 177);
}

TEST(QrEncoder, ByteModeKeepsNulAndUtf8)
{
    /* encodeString would stop at the NUL; encodeData keeps every byte. */
    const QByteArray withNul("a\0b", 3);
    const QrEncoder::Result r = QrEncoder::encode(withNul, QrEncoder::Level::Low);
    ASSERT_EQ(r.error, QrEncoder::Error::None);
    EXPECT_EQ(readCodes(magnified(r.image)), QStringList{QString::fromLatin1(withNul)});

    const QString utf8Text = QStringLiteral("WIFI:S:caf\u00e9 \u2615;T:WPA;P:\u00fcber-geheim;;");
    const QrEncoder::Result u = QrEncoder::encode(utf8Text.toUtf8());
    ASSERT_EQ(u.error, QrEncoder::Error::None);
    EXPECT_EQ(readCodes(magnified(u.image)), QStringList{utf8Text});
}

TEST(QrEncoder, QuietZone)
{
    for (int zone : {0, 1, 4, 16}) {
        const QrEncoder::Result r = QrEncoder::encode("HELLO", QrEncoder::Level::Low, zone);
        ASSERT_EQ(r.error, QrEncoder::Error::None);
        EXPECT_EQ(r.image.width(), r.modules + 2 * zone);
        EXPECT_EQ(r.image.height(), r.modules + 2 * zone);
        EXPECT_EQ(r.image.format(), QImage::Format_Grayscale8);
        /* All light around the code, and the top-left finder's corner dark just inside it. */
        for (int i = 0; i < zone; ++i) {
            for (int j = 0; j < r.image.width(); ++j) {
                EXPECT_EQ(r.image.constScanLine(i)[j], 255);
                EXPECT_EQ(r.image.constScanLine(r.image.height() - 1 - i)[j], 255);
                EXPECT_EQ(r.image.constScanLine(j)[i], 255);
                EXPECT_EQ(r.image.constScanLine(j)[r.image.width() - 1 - i], 255);
            }
        }
        EXPECT_EQ(r.image.constScanLine(zone)[zone], 0);
    }
    /* Clamped to 0..16. */
    EXPECT_EQ(QrEncoder::encode("HELLO", QrEncoder::Level::Low, -3).image.width(), 21);
    EXPECT_EQ(QrEncoder::encode("HELLO", QrEncoder::Level::Low, 99).image.width(), 21 + 32);
}

TEST(QrEncoder, NothingAndTooMuch)
{
    EXPECT_EQ(QrEncoder::encode(QByteArray()).error, QrEncoder::Error::Empty);
    EXPECT_TRUE(QrEncoder::encode(QByteArray()).image.isNull());
    EXPECT_EQ(QrEncoder::encode(QByteArray(2954, 'a'), QrEncoder::Level::Low).error,
              QrEncoder::Error::TooLong);
    /* High holds 1273 bytes at version 40: libqrencode's ERANGE. */
    const QrEncoder::Result r = QrEncoder::encode(QByteArray(1274, 'a'), QrEncoder::Level::High);
    EXPECT_EQ(r.error, QrEncoder::Error::TooLong);
    EXPECT_TRUE(r.image.isNull());
    EXPECT_EQ(r.modules, 0);
    EXPECT_EQ(QrEncoder::encode(QByteArray(1273, 'a'), QrEncoder::Level::High).error,
              QrEncoder::Error::None);
}

TEST(QrCodeItem, WholePixelsPerModuleWhenThereIsRoom)
{
    /* 37 modules (version 3 with its quiet zone) in 200: 5 px each, 185, centred. */
    EXPECT_EQ(QrCodeItem::codeRect(QSizeF(200, 200), 37), QRectF(7, 7, 185, 185));
    /* Square in the smaller side, centred in the larger. */
    EXPECT_EQ(QrCodeItem::codeRect(QSizeF(300, 100), 25), QRectF(100, 0, 100, 100));
    EXPECT_EQ(QrCodeItem::codeRect(QSizeF(100, 300), 25), QRectF(0, 100, 100, 100));
    /* Less than a pixel a module: a fraction, filling what there is. */
    const QRectF tiny = QrCodeItem::codeRect(QSizeF(20, 20), 29);
    EXPECT_DOUBLE_EQ(tiny.width(), 20.0);
    EXPECT_DOUBLE_EQ(tiny.height(), 20.0);
    EXPECT_TRUE(QrCodeItem::codeRect(QSizeF(0, 100), 29).isNull());
    EXPECT_TRUE(QrCodeItem::codeRect(QSizeF(100, 100), 0).isNull());
}

TEST(QrCodeItem, TextMakesACode)
{
    QrCodeItem item;
    QSignalSpy code(&item, &QrCodeItem::codeChanged);
    QSignalSpy text(&item, &QrCodeItem::textChanged);
    EXPECT_FALSE(item.valid());
    EXPECT_EQ(item.moduleCount(), 0);

    item.setText(QStringLiteral("HELLO"));
    EXPECT_TRUE(item.valid());
    EXPECT_EQ(item.error(), QString());
    EXPECT_GE(item.moduleCount(), 21);
    EXPECT_EQ(text.count(), 1);
    EXPECT_EQ(code.count(), 1);
    EXPECT_EQ(item.implicitWidth(), (item.moduleCount() + 8) * 4);

    /* The same text again changes nothing. */
    item.setText(QStringLiteral("HELLO"));
    EXPECT_EQ(text.count(), 1);
    EXPECT_EQ(code.count(), 1);

    item.setText(QString());
    EXPECT_FALSE(item.valid());
    EXPECT_EQ(item.error(), QString());
    EXPECT_EQ(item.implicitWidth(), 0);
}

TEST(QrCodeItem, TooMuchTextSaysSo)
{
    QrCodeItem item;
    item.setErrorCorrection(QrCodeItem::High);
    item.setText(QString(1274, QLatin1Char('a')));
    EXPECT_FALSE(item.valid());
    EXPECT_EQ(item.error(), QStringLiteral("tooLong"));
    /* Less correction makes room. */
    item.setErrorCorrection(QrCodeItem::Low);
    EXPECT_TRUE(item.valid());
    EXPECT_EQ(item.error(), QString());
}

TEST(QrCodeItem, PaintsAReadableCode)
{
    WifiQrCode wifi;
    const QString text = wifi.compose(QStringLiteral("Home;Net"), QStringLiteral("psk"),
                                      QStringLiteral("p:a\\ss,word"));
    ASSERT_FALSE(text.isEmpty());

    QrCodeItem item;
    item.setText(text);
    item.setSize(QSizeF(330, 260));

    QImage canvas(330, 260, QImage::Format_ARGB32_Premultiplied);
    canvas.fill(Qt::white);
    {
        QPainter painter(&canvas);
        item.paint(&painter);
    }
    const QStringList read = readCodes(canvas);
    ASSERT_EQ(read, QStringList{text});
    EXPECT_TRUE(wifi.parse(read.first()).value(QStringLiteral("valid")).toBool());
    EXPECT_EQ(wifi.parse(read.first()).value(QStringLiteral("passphrase")).toString(),
              QStringLiteral("p:a\\ss,word"));
}

TEST(QrCodeItem, PaintsInItsColours)
{
    QrCodeItem item;
    item.setText(QStringLiteral("HELLO"));
    item.setQuietZone(4);
    item.setColor(QColor(0, 0, 128));
    item.setBackgroundColor(QColor(255, 255, 200));
    const int side = item.moduleCount() + 8;
    item.setSize(QSizeF(side * 4, side * 4));

    QImage canvas(side * 4, side * 4, QImage::Format_ARGB32_Premultiplied);
    canvas.fill(Qt::transparent);
    {
        QPainter painter(&canvas);
        item.paint(&painter);
    }
    /* The quiet zone in the background colour, the finder's corner in the code's. */
    EXPECT_EQ(canvas.pixelColor(1, 1), QColor(255, 255, 200));
    EXPECT_EQ(canvas.pixelColor(4 * 4 + 1, 4 * 4 + 1), QColor(0, 0, 128));
    /* Every pixel one or the other: no blurred edges between modules. */
    for (int y = 0; y < canvas.height(); ++y) {
        for (int x = 0; x < canvas.width(); ++x) {
            const QColor c = canvas.pixelColor(x, y);
            ASSERT_TRUE(c == QColor(0, 0, 128) || c == QColor(255, 255, 200)) << x << "," << y;
        }
    }
    EXPECT_EQ(readCodes(canvas), QStringList{QStringLiteral("HELLO")});
}

TEST(QrCodeItem, NothingPaintedWithoutACode)
{
    QrCodeItem item;
    item.setSize(QSizeF(50, 50));
    QImage canvas(50, 50, QImage::Format_ARGB32_Premultiplied);
    canvas.fill(Qt::transparent);
    {
        QPainter painter(&canvas);
        item.paint(&painter);
    }
    EXPECT_EQ(canvas.pixelColor(25, 25).alpha(), 0);
}
