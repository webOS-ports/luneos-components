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

#include "barcodedecoder.h"

#include <zbar.h>

#include <algorithm>

namespace BarcodeDecoder {

// zbar.h puts its C API in namespace zbar when compiled as C++.
using namespace zbar;

LumaImage extractLuma(const uchar *plane, int width, int height, int bytesPerLine,
                      int pixelStride, int offset, int step)
{
    LumaImage image;
    if (!plane || width <= 0 || height <= 0 || pixelStride <= 0 || offset < 0
        || offset >= pixelStride || step <= 0)
        return image;
    // The last sample of a row must lie inside the row.
    if (qint64(width - 1) * pixelStride + offset >= bytesPerLine)
        return image;

    const int outWidth = (width + step - 1) / step;
    const int outHeight = (height + step - 1) / step;
    image.pixels.resize(qsizetype(outWidth) * outHeight);
    uchar *out = reinterpret_cast<uchar *>(image.pixels.data());

    for (int y = 0; y < outHeight; ++y) {
        const uchar *row = plane + qint64(y) * step * bytesPerLine + offset;
        for (int x = 0; x < outWidth; ++x)
            *out++ = row[qint64(x) * step * pixelStride];
    }
    image.width = outWidth;
    image.height = outHeight;
    return image;
}

int stepFor(int width, int height, int maxSide)
{
    if (maxSide <= 0)
        return 1;
    const int longer = std::max(width, height);
    int step = 1;
    while ((longer + step - 1) / step > maxSide)
        ++step;
    return step;
}

static void enableSymbologies(zbar_image_scanner_t *scanner, Symbologies symbologies)
{
    if (symbologies == Symbologies::All) {
        zbar_image_scanner_set_config(scanner, ZBAR_NONE, ZBAR_CFG_ENABLE, 1);
        return;
    }
    zbar_image_scanner_set_config(scanner, ZBAR_NONE, ZBAR_CFG_ENABLE, 0);
    for (const zbar_symbol_type_t type : { ZBAR_QRCODE, ZBAR_EAN13, ZBAR_EAN8, ZBAR_UPCA,
                                           ZBAR_UPCE, ZBAR_ISBN13, ZBAR_CODE128, ZBAR_CODE39 })
        zbar_image_scanner_set_config(scanner, type, ZBAR_CFG_ENABLE, 1);
    for (const zbar_symbol_type_t type : { ZBAR_CODE128, ZBAR_CODE39 })
        zbar_image_scanner_set_config(scanner, type, ZBAR_CFG_MIN_LEN, 6);
}

bool needsConfirmation(const QString &format)
{
    return format != QLatin1String("QR-Code");
}

QList<Symbol> decode(const LumaImage &image, Symbologies symbologies)
{
    QList<Symbol> symbols;
    if (!image.isValid())
        return symbols;

    zbar_image_scanner_t *scanner = zbar_image_scanner_create();
    if (!scanner)
        return symbols;
    enableSymbologies(scanner, symbologies);

    zbar_image_t *zimage = zbar_image_create();
    if (!zimage) {
        zbar_image_scanner_destroy(scanner);
        return symbols;
    }
    zbar_image_set_format(zimage, zbar_fourcc('Y', '8', '0', '0'));
    zbar_image_set_size(zimage, unsigned(image.width), unsigned(image.height));
    // zbar only reads the data; no cleanup handler, the QByteArray owns it.
    zbar_image_set_data(zimage, image.pixels.constData(), static_cast<unsigned long>(image.pixels.size()), nullptr);

    if (zbar_scan_image(scanner, zimage) > 0) {
        for (const zbar_symbol_t *s = zbar_image_first_symbol(zimage); s; s = zbar_symbol_next(s)) {
            const char *data = zbar_symbol_get_data(s);
            const unsigned length = zbar_symbol_get_data_length(s);
            symbols.append(Symbol{
                QString::fromUtf8(data, qsizetype(length)),
                QString::fromLatin1(zbar_get_symbol_name(zbar_symbol_get_type(s))),
            });
        }
    }

    zbar_image_destroy(zimage);
    zbar_image_scanner_destroy(scanner);
    return symbols;
}

} // namespace BarcodeDecoder
