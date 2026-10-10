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

#include <QCoreApplication>
#include <QElapsedTimer>
#include <QThreadPool>
#include <QVideoFrame>
#include <QVideoSink>

#include <cstring>
#include <memory>
#include <string>

#include "barcodescanner.h"

/* The same EAN-13 drawing as in test_barcodedecoder.cpp, as a Y8 video frame. */
static QVideoFrame ean13Frame(const std::string &digits, int module = 3, int height = 120)
{
    static const char *const kOddL[] = { "0001101", "0011001", "0010011", "0111101", "0100011",
                                         "0110001", "0101111", "0111011", "0110111", "0001011" };
    static const char *const kEvenG[] = { "0100111", "0110011", "0011011", "0100001", "0011101",
                                          "0111001", "0000101", "0010001", "0001001", "0010111" };
    static const char *const kRight[] = { "1110010", "1100110", "1101100", "1000010", "1011100",
                                          "1001110", "1010000", "1000100", "1001000", "1110100" };
    static const char *const kParity[] = { "LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
                                           "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL" };
    std::string bits = "101";
    for (int i = 1; i <= 6; ++i) {
        const char *const *set = (kParity[digits[0] - '0'][i - 1] == 'L') ? kOddL : kEvenG;
        bits += set[digits[i] - '0'];
    }
    bits += "01010";
    for (int i = 7; i <= 12; ++i)
        bits += kRight[digits[i] - '0'];
    bits += "101";

    const int quiet = 12;
    const int width = int(bits.size() + 2 * quiet) * module;
    QVideoFrame frame(QVideoFrameFormat(QSize(width, height), QVideoFrameFormat::Format_Y8));
    if (!frame.map(QVideoFrame::WriteOnly))
        return QVideoFrame();
    for (int y = 0; y < height; ++y) {
        uchar *row = frame.bits(0) + qsizetype(y) * frame.bytesPerLine(0);
        for (int x = 0; x < width; ++x) {
            const int m = x / module - quiet;
            row[x] = (m >= 0 && m < int(bits.size()) && bits[size_t(m)] == '1') ? 0 : 255;
        }
    }
    frame.unmap();
    return frame;
}

/* Runs the event loop until `done` or a timeout, giving the worker time. */
template <typename Pred>
static bool spinUntil(Pred done, int timeoutMs = 3000)
{
    QElapsedTimer t;
    t.start();
    while (!done() && t.elapsed() < timeoutMs)
        QCoreApplication::processEvents(QEventLoop::AllEvents, 20);
    return done();
}

class BarcodeScannerTest : public ::testing::Test
{
protected:
    QVideoSink sink;
    BarcodeScanner scanner;
    QStringList texts;

    void SetUp() override
    {
        scanner.setVideoSink(&sink);
        scanner.setInterval(0);
        QObject::connect(&scanner, &BarcodeScanner::decoded, &scanner,
                         [this](const QString &text, const QString &) { texts.append(text); });
    }

    void TearDown() override
    {
        QThreadPool::globalInstance()->waitForDone();
        QCoreApplication::processEvents();
    }
};

TEST_F(BarcodeScannerTest, ReportsACodeInView)
{
    scanner.setActive(true);
    sink.setVideoFrame(ean13Frame("4006381333931"));
    ASSERT_TRUE(spinUntil([this] { return !texts.isEmpty(); }));
    EXPECT_EQ(texts, QStringList({ "4006381333931" }));
}

TEST_F(BarcodeScannerTest, InactiveLooksAtNothing)
{
    sink.setVideoFrame(ean13Frame("4006381333931"));
    QThreadPool::globalInstance()->waitForDone();
    spinUntil([] { return false; }, 200);
    EXPECT_TRUE(texts.isEmpty());
}

TEST_F(BarcodeScannerTest, ACodeThatStaysInViewIsReportedOnce)
{
    scanner.setActive(true);
    for (int i = 0; i < 20; ++i) {
        // A new frame each time, as a camera delivers them: the sink does not
        // announce the same frame twice.
        sink.setVideoFrame(ean13Frame("4006381333931"));
        QThreadPool::globalInstance()->waitForDone();
        QCoreApplication::processEvents();
    }
    EXPECT_EQ(texts.size(), 1);
}

TEST_F(BarcodeScannerTest, AnotherCodeIsReportedToo)
{
    scanner.setActive(true);
    sink.setVideoFrame(ean13Frame("4006381333931"));
    ASSERT_TRUE(spinUntil([this] { return texts.size() == 1; }));
    sink.setVideoFrame(ean13Frame("5901234123457"));
    ASSERT_TRUE(spinUntil([this] { return texts.size() == 2; }));
    EXPECT_EQ(texts.last(), QStringLiteral("5901234123457"));
}

TEST_F(BarcodeScannerTest, ABurstOfFramesIsReportedOnce)
{
    scanner.setActive(true);
    // Distinct frames (the sink does not announce the same one twice), ready
    // beforehand so they arrive far faster than they decode: frames come in
    // while a decode is running, and under TSan this is where the worker and
    // the GUI thread meet.
    QList<QVideoFrame> frames;
    for (int i = 0; i < 200; ++i)
        frames.append(ean13Frame("4006381333931"));
    for (const QVideoFrame &frame : frames)
        sink.setVideoFrame(frame);
    QThreadPool::globalInstance()->waitForDone();
    QCoreApplication::processEvents();
    EXPECT_EQ(texts.size(), 1);
}

TEST(BarcodeScanner, ScannerDeletedWhileDecoding)
{
    QVideoSink sink;
    auto scanner = std::make_unique<BarcodeScanner>();
    scanner->setVideoSink(&sink);
    scanner->setActive(true);
    sink.setVideoFrame(ean13Frame("4006381333931"));
    // The worker may still be running; its result must go nowhere.
    scanner.reset();
    QThreadPool::globalInstance()->waitForDone();
    QCoreApplication::processEvents();
    SUCCEED();
}
