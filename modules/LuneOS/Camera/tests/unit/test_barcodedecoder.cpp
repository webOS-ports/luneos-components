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

#include <gtest/gtest.h>

#include <string>
#include <vector>

#include "barcodedecoder.h"

using namespace BarcodeDecoder;

/*
 * An EAN-13 barcode drawn from its definition (GS1 General Specifications,
 * 5.2.1), as the luminance plane a camera would deliver: black bars on white,
 * `module` pixels per module, with quiet zones and `stride` bytes per row.
 */
static std::vector<uchar> drawEan13(const std::string &digits, int module, int height,
                                    int stride, int pixelStride = 1, int offset = 0)
{
    static const char *const kOddL[] = { "0001101", "0011001", "0010011", "0111101", "0100011",
                                      "0110001", "0101111", "0111011", "0110111", "0001011" };
    static const char *const kEvenG[] = { "0100111", "0110011", "0011011", "0100001", "0011101",
                                      "0111001", "0000101", "0010001", "0001001", "0010111" };
    static const char *const kRight[] = { "1110010", "1100110", "1101100", "1000010", "1011100",
                                      "1001110", "1010000", "1000100", "1001000", "1110100" };
    static const char *const parity[] = { "LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
                                          "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL" };

    std::string bits = "101";
    const char *p = parity[digits[0] - '0'];
    for (int i = 1; i <= 6; ++i)
    {
        const char *const *set = (p[i - 1] == 'L') ? kOddL : kEvenG;
        bits += set[digits[i] - '0'];
    }
    bits += "01010";
    for (int i = 7; i <= 12; ++i)
        bits += kRight[digits[i] - '0'];
    bits += "101";

    const int quiet = 12;
    const int width = int(bits.size() + 2 * quiet) * module;
    std::vector<uchar> plane(size_t(stride) * height, 0x55); // padding: grey
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            const int m = x / module - quiet;
            const bool bar = m >= 0 && m < int(bits.size()) && bits[size_t(m)] == '1';
            plane[size_t(y) * stride + size_t(x) * pixelStride + offset] = bar ? 0 : 255;
        }
    }
    return plane;
}

static int ean13Width(int module)
{
    return (95 + 24) * module;
}

TEST(ExtractLuma, SkipsRowPadding)
{
    const uchar plane[] = { 1, 2, 3, 99,
                            4, 5, 6, 99 };
    const LumaImage image = extractLuma(plane, 3, 2, 4);
    ASSERT_TRUE(image.isValid());
    EXPECT_EQ(image.width, 3);
    EXPECT_EQ(image.height, 2);
    EXPECT_EQ(image.pixels, QByteArray("\x01\x02\x03\x04\x05\x06", 6));
}

TEST(ExtractLuma, PackedYuvTakesEveryOtherByte)
{
    // UYVY: U Y V Y - the luminance is at odd offsets.
    const uchar plane[] = { 9, 1, 9, 2, 9, 3, 9, 4 };
    const LumaImage image = extractLuma(plane, 4, 1, 8, 2, 1);
    ASSERT_TRUE(image.isValid());
    EXPECT_EQ(image.pixels, QByteArray("\x01\x02\x03\x04", 4));
}

TEST(ExtractLuma, StepSubsamples)
{
    const uchar plane[] = { 1, 2, 3,
                            4, 5, 6,
                            7, 8, 9 };
    const LumaImage image = extractLuma(plane, 3, 3, 3, 1, 0, 2);
    ASSERT_TRUE(image.isValid());
    EXPECT_EQ(image.width, 2);
    EXPECT_EQ(image.height, 2);
    EXPECT_EQ(image.pixels, QByteArray("\x01\x03\x07\x09", 4));
}

TEST(ExtractLuma, RefusesWhatWouldReadOutOfBounds)
{
    const uchar plane[16] = {};
    // A row stride shorter than the row.
    EXPECT_FALSE(extractLuma(plane, 4, 2, 3).isValid());
    // Packed samples running past the stride.
    EXPECT_FALSE(extractLuma(plane, 4, 2, 7, 2, 1).isValid());
    EXPECT_FALSE(extractLuma(plane, 4, 2, 8, 2, 2).isValid());
    EXPECT_FALSE(extractLuma(nullptr, 4, 2, 4).isValid());
    EXPECT_FALSE(extractLuma(plane, 0, 2, 4).isValid());
    EXPECT_FALSE(extractLuma(plane, 4, 2, 4, 1, 0, 0).isValid());
}

TEST(StepFor, BringsTheLongerSideDown)
{
    EXPECT_EQ(stepFor(1280, 960, 1280), 1);
    EXPECT_EQ(stepFor(1281, 960, 1280), 2);
    EXPECT_EQ(stepFor(4000, 3000, 1280), 4);
    EXPECT_EQ(stepFor(3000, 4000, 1280), 4);
    EXPECT_EQ(stepFor(100, 100, 0), 1);
}

TEST(Decode, ReadsAnEan13)
{
    const int module = 3, height = 120;
    const int width = ean13Width(module);
    const std::vector<uchar> plane = drawEan13("4006381333931", module, height, width + 16);
    const LumaImage image = extractLuma(plane.data(), width, height, width + 16);
    const QList<Symbol> symbols = decode(image);
    ASSERT_EQ(symbols.size(), 1);
    EXPECT_EQ(symbols[0].text, QStringLiteral("4006381333931"));
    EXPECT_EQ(symbols[0].format, QStringLiteral("EAN-13"));
}

TEST(Decode, ReadsItFromPackedYuvAtHalfSize)
{
    const int module = 4, height = 120;
    const int width = ean13Width(module);
    const int stride = width * 2;
    const std::vector<uchar> plane = drawEan13("4006381333931", module, height, stride, 2, 1);
    const LumaImage image = extractLuma(plane.data(), width, height, stride, 2, 1, 2);
    const QList<Symbol> symbols = decode(image);
    ASSERT_EQ(symbols.size(), 1);
    EXPECT_EQ(symbols[0].text, QStringLiteral("4006381333931"));
}

TEST(Decode, NothingInABlankFrame)
{
    LumaImage blank;
    blank.width = 64;
    blank.height = 48;
    blank.pixels = QByteArray(64 * 48, char(200));
    EXPECT_TRUE(decode(blank).isEmpty());
    EXPECT_TRUE(decode(LumaImage()).isEmpty());
}

/* An Interleaved 2 of 5 code: digit pairs, the first in the widths of five
 * bars, the second in the five spaces between them; two of each five wide. */
static LumaImage drawInterleaved2of5(const std::string &digits, int narrow = 3, int height = 80)
{
    static const char *const kWidths[] = { "nnwwn", "wnnnw", "nwnnw", "wwnnn", "nnwnw",
                                           "wnwnn", "nwwnn", "nnnww", "wnnwn", "nwnwn" };
    const int wide = narrow * 3;
    std::vector<std::pair<bool, int>> runs = { { true, narrow }, { false, narrow },
                                               { true, narrow }, { false, narrow } };
    for (size_t i = 0; i + 1 < digits.size(); i += 2) {
        for (int k = 0; k < 5; ++k) {
            runs.push_back({ true, kWidths[digits[i] - '0'][k] == 'w' ? wide : narrow });
            runs.push_back({ false, kWidths[digits[i + 1] - '0'][k] == 'w' ? wide : narrow });
        }
    }
    runs.push_back({ true, wide });
    runs.push_back({ false, narrow });
    runs.push_back({ true, narrow });

    const int quiet = 10 * narrow;
    std::string row(size_t(quiet), char(255));
    for (const auto &run : runs)
        row.append(size_t(run.second), run.first ? char(0) : char(255));
    row.append(size_t(quiet), char(255));

    LumaImage image;
    image.width = int(row.size());
    image.height = height;
    for (int y = 0; y < height; ++y)
        image.pixels.append(row.data(), qsizetype(row.size()));
    return image;
}

/* The drawing is a valid code: with every symbology on, zbar reads it. */
TEST(Decode, EverySymbologyReadsInterleaved2of5)
{
    const QList<Symbol> symbols = decode(drawInterleaved2of5("12345670"), Symbologies::All);
    ASSERT_EQ(symbols.size(), 1);
    EXPECT_EQ(symbols[0].text, QStringLiteral("12345670"));
    EXPECT_EQ(symbols[0].format, QStringLiteral("I2/5"));
}

/* What reads codes in faces is left out of what a phone looks for. */
TEST(Decode, PhoneSymbologiesIgnoreInterleaved2of5)
{
    EXPECT_TRUE(decode(drawInterleaved2of5("12345670")).isEmpty());
}

TEST(NeedsConfirmation, LinearCodesDoQrCodesDoNot)
{
    EXPECT_TRUE(needsConfirmation(QStringLiteral("EAN-13")));
    EXPECT_TRUE(needsConfirmation(QStringLiteral("CODE-128")));
    EXPECT_FALSE(needsConfirmation(QStringLiteral("QR-Code")));
}
