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

#ifndef BARCODEDECODER_H
#define BARCODEDECODER_H

#include <QByteArray>
#include <QList>
#include <QString>

/*
 * The frame handling and decoding behind BarcodeScanner, free of Qt
 * Multimedia and threads so it can be tested on its own.
 */
namespace BarcodeDecoder {

/* An 8-bit greyscale image, rows packed without padding. */
struct LumaImage {
    QByteArray pixels;
    int width = 0;
    int height = 0;

    bool isValid() const
    {
        return width > 0 && height > 0 && pixels.size() == qsizetype(width) * height;
    }
};

/*
 * Copies the luminance out of a plane in which every pixelStride-th byte of a
 * row is a Y sample: 1 for the Y plane of planar and semi-planar YUV (I420,
 * NV12, NV21 ...), 2 for packed 4:2:2 (YUYV with offset 0, UYVY with offset 1).
 * step keeps every step-th sample in each direction, to bring large frames
 * down to a size a phone decodes quickly. Returns an invalid image for
 * nonsensical arguments, including a stride too short for the row.
 */
LumaImage extractLuma(const uchar *plane, int width, int height, int bytesPerLine,
                      int pixelStride = 1, int offset = 0, int step = 1);

/* The smallest step that brings the longer side down to maxSide or below. */
int stepFor(int width, int height, int maxSide);

struct Symbol {
    QString text;
    QString format; // zbar's name for the symbology: "QR-Code", "EAN-13" ...
};

/* Every barcode zbar finds in the image. */
QList<Symbol> decode(const LumaImage &image);

} // namespace BarcodeDecoder

#endif // BARCODEDECODER_H
