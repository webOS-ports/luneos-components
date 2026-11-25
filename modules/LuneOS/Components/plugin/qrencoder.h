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

#ifndef QRENCODER_H
#define QRENCODER_H

#include <QByteArray>
#include <QImage>

/*
 * Turns text into a QR code with libqrencode, free of Qt Quick so it can be
 * tested on its own (the tests read what it draws back with zbar).
 */
namespace QrEncoder {

/* How much of the code may be lost and still read: 7, 15, 25 or 30%. */
enum class Level { Low, Medium, Quartile, High };

enum class Error {
    None,
    Empty,        // nothing to encode
    TooLong,      // more than a version 40 code holds at this level
    Unavailable,  // built without libqrencode
    Failed,       // libqrencode said no for another reason (out of memory)
};

struct Result {
    Error error = Error::None;
    /*
     * One pixel per module, Format_Grayscale8, 0 for dark and 255 for light,
     * with quietZone light modules on every side. Null unless error is None.
     */
    QImage image;
    /* Modules along a side, the quiet zone not counted (21 for version 1). */
    int modules = 0;
};

/*
 * data as bytes in byte mode (UTF-8 for text, which every phone reads), in
 * the smallest version that holds it. quietZone is clamped to 0..16; the
 * standard asks for 4.
 */
Result encode(const QByteArray &data, Level level = Level::Medium, int quietZone = 4);

/* Whether this build can encode at all. */
bool available();

} // namespace QrEncoder

#endif // QRENCODER_H
