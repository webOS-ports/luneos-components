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

#include "qrencoder.h"

#include <QtGlobal>

#include <cerrno>

#ifdef HAVE_QRENCODE
#include <qrencode.h>
#endif

namespace QrEncoder {

bool available()
{
#ifdef HAVE_QRENCODE
    return true;
#else
    return false;
#endif
}

#ifdef HAVE_QRENCODE

namespace {

QRecLevel toQrLevel(Level level)
{
    switch (level) {
    case Level::Low: return QR_ECLEVEL_L;
    case Level::Medium: return QR_ECLEVEL_M;
    case Level::Quartile: return QR_ECLEVEL_Q;
    case Level::High: return QR_ECLEVEL_H;
    }
    return QR_ECLEVEL_M;
}

} // namespace

Result encode(const QByteArray &data, Level level, int quietZone)
{
    Result result;
    if (data.isEmpty()) {
        result.error = Error::Empty;
        return result;
    }
    /* A version 40 code holds 2953 bytes at most; libqrencode takes an int. */
    if (data.size() > 2953) {
        result.error = Error::TooLong;
        return result;
    }

    quietZone = qBound(0, quietZone, 16);

    /*
     * encodeData rather than encodeString: the whole of data in byte mode,
     * with no NUL ending it early and no guessing at Kanji.
     */
    errno = 0;
    QRcode *code = QRcode_encodeData(int(data.size()),
                                     reinterpret_cast<const unsigned char *>(data.constData()),
                                     0, toQrLevel(level));
    if (!code) {
        result.error = errno == ERANGE ? Error::TooLong : Error::Failed;
        return result;
    }

    const int modules = code->width;
    const int side = modules + 2 * quietZone;
    QImage image(side, side, QImage::Format_Grayscale8);
    if (image.isNull()) {
        QRcode_free(code);
        result.error = Error::Failed;
        return result;
    }
    image.fill(255);

    for (int y = 0; y < modules; ++y) {
        uchar *row = image.scanLine(y + quietZone) + quietZone;
        const unsigned char *src = code->data + qsizetype(y) * modules;
        /* Bit 0 of each byte is the module: 1 dark, 0 light. */
        for (int x = 0; x < modules; ++x)
            row[x] = (src[x] & 1) ? 0 : 255;
    }
    QRcode_free(code);

    result.image = image;
    result.modules = modules;
    return result;
}

#else // !HAVE_QRENCODE

Result encode(const QByteArray &data, Level level, int quietZone)
{
    Q_UNUSED(level);
    Q_UNUSED(quietZone);
    Result result;
    result.error = data.isEmpty() ? Error::Empty : Error::Unavailable;
    return result;
}

#endif

} // namespace QrEncoder
