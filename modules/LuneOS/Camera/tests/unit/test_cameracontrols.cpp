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

#include <QTransform>

#include <cmath>

#include <gst/interfaces/photography.h>

#include "cameracontrols.h"

using namespace CameraControls;

TEST(Modes, NamesAreTheAndroidValues)
{
    EXPECT_EQ(modeName(ModeKind::Flash, GST_PHOTOGRAPHY_FLASH_MODE_RED_EYE), "red-eye");
    EXPECT_EQ(modeName(ModeKind::WhiteBalance, GST_PHOTOGRAPHY_WB_MODE_CLOUDY), "cloudy-daylight");
    EXPECT_EQ(modeName(ModeKind::Scene, GST_PHOTOGRAPHY_SCENE_MODE_HDR), "hdr");
    // gst-droid sends the manual scene mode as Android's "auto".
    EXPECT_EQ(modeName(ModeKind::Scene, GST_PHOTOGRAPHY_SCENE_MODE_MANUAL), "auto");
    EXPECT_EQ(modeName(ModeKind::ColorTone, GST_PHOTOGRAPHY_COLOR_TONE_MODE_GRAYSCALE), "mono");
    EXPECT_EQ(modeName(ModeKind::Focus, GST_PHOTOGRAPHY_FOCUS_MODE_HYPERFOCAL), "fixed");
    EXPECT_EQ(modeName(ModeKind::Flicker, GST_PHOTOGRAPHY_FLICKER_REDUCTION_50HZ), "50hz");
}

TEST(Modes, RoundTripEveryName)
{
    const ModeKind kinds[] = { ModeKind::Flash, ModeKind::Focus, ModeKind::WhiteBalance,
                               ModeKind::Scene, ModeKind::ColorTone, ModeKind::Flicker };
    for (ModeKind kind : kinds) {
        for (int value = 0; value < 64; ++value) {
            const QString name = modeName(kind, value);
            if (name.isEmpty())
                continue;
            // Two focus modes share "continuous"; the name maps back to the first.
            EXPECT_EQ(modeName(kind, modeValue(kind, name)), name);
        }
    }
}

TEST(Modes, UnknownValuesAndNames)
{
    EXPECT_TRUE(modeName(ModeKind::Flash, 9999).isEmpty());
    EXPECT_EQ(modeValue(ModeKind::Flash, QStringLiteral("blinding")), -1);
    // A name of one kind is not a name of another.
    EXPECT_EQ(modeValue(ModeKind::Flash, QStringLiteral("cloudy-daylight")), -1);
}

TEST(Modes, NamesDropDuplicatesAndUnknowns)
{
    const QStringList names = modeNames(ModeKind::Focus, {
        GST_PHOTOGRAPHY_FOCUS_MODE_AUTO,
        GST_PHOTOGRAPHY_FOCUS_MODE_CONTINUOUS_NORMAL,
        GST_PHOTOGRAPHY_FOCUS_MODE_CONTINUOUS_EXTENDED,
        GST_PHOTOGRAPHY_FOCUS_MODE_PORTRAIT, // gst-droid has no Android value for it
        GST_PHOTOGRAPHY_FOCUS_MODE_MACRO,
    });
    EXPECT_EQ(names, QStringList({ "auto", "continuous", "macro" }));
}

TEST(Zoom, ParsesTheHalList)
{
    EXPECT_EQ(parseZoomRatios(QStringLiteral("100,102,104,800")), QList<int>({ 100, 102, 104, 800 }));
    EXPECT_EQ(parseZoomRatios(QStringLiteral(" 100, 200 ")), QList<int>({ 100, 200 }));
    EXPECT_TRUE(parseZoomRatios(QString()).isEmpty());
    // A list that does not parse completely is not trusted at all.
    EXPECT_TRUE(parseZoomRatios(QStringLiteral("100,abc,300")).isEmpty());
    EXPECT_TRUE(parseZoomRatios(QStringLiteral("100,-200")).isEmpty());
    EXPECT_TRUE(parseZoomRatios(QStringLiteral("100,0")).isEmpty());
}

TEST(Zoom, PicksTheLargestRatioNotAboveTheWish)
{
    const QList<int> ratios = { 100, 125, 150, 200, 400 };
    EXPECT_EQ(zoomIndexForRatio(ratios, 1.0), 0);
    EXPECT_EQ(zoomIndexForRatio(ratios, 1.49), 1);
    EXPECT_EQ(zoomIndexForRatio(ratios, 1.5), 2);
    EXPECT_EQ(zoomIndexForRatio(ratios, 3.9), 3);
    EXPECT_EQ(zoomIndexForRatio(ratios, 10.0), 4);
    // Below the smallest ratio there is nothing smaller to pick.
    EXPECT_EQ(zoomIndexForRatio(ratios, 0.5), 0);
    EXPECT_EQ(zoomIndexForRatio({}, 2.0), 0);
}

TEST(Zoom, ToleratesPinchArithmetic)
{
    const QList<int> ratios = { 100, 150, 200 };
    // 2.0 as it comes out of repeated pinch scaling.
    qreal pinched = 1.0;
    for (int i = 0; i < 10; ++i)
        pinched *= std::pow(2.0, 0.1);
    EXPECT_EQ(zoomIndexForRatio(ratios, pinched), 2);
}

TEST(Zoom, UnsortedListsStillPickByValue)
{
    EXPECT_EQ(zoomIndexForRatio({ 200, 100, 150 }, 1.6), 2);
    EXPECT_DOUBLE_EQ(maximumZoomRatio({ 200, 800, 100 }), 8.0);
    EXPECT_DOUBLE_EQ(maximumZoomRatio({}), 1.0);
}

TEST(FocusRegion, CentredSquare)
{
    EXPECT_EQ(focusRegion(QPointF(0.5, 0.5), QSize(2000, 2000)), QRect(900, 900, 200, 200));
    // The side follows the shorter side of the frame.
    EXPECT_EQ(focusRegion(QPointF(0.5, 0.5), QSize(4000, 1000), 0.2), QRect(1900, 400, 200, 200));
}

TEST(FocusRegion, StaysInsideTheFrame)
{
    EXPECT_EQ(focusRegion(QPointF(0.0, 0.0), QSize(2000, 2000)), QRect(0, 0, 200, 200));
    EXPECT_EQ(focusRegion(QPointF(1.0, 1.0), QSize(2000, 2000)), QRect(1800, 1800, 200, 200));
    EXPECT_EQ(focusRegion(QPointF(0.99, 0.01), QSize(2000, 2000)), QRect(1800, 0, 200, 200));
}

TEST(FocusRegion, RejectsNonsense)
{
    EXPECT_TRUE(focusRegion(QPointF(-0.1, 0.5), QSize(2000, 2000)).isEmpty());
    EXPECT_TRUE(focusRegion(QPointF(0.5, 1.1), QSize(2000, 2000)).isEmpty());
    EXPECT_TRUE(focusRegion(QPointF(0.5, 0.5), QSize()).isEmpty());
    // A tiny frame still gets a region of at least one pixel.
    EXPECT_EQ(focusRegion(QPointF(0.5, 0.5), QSize(3, 3)), QRect(1, 1, 1, 1));
}

/*
 * The forward transform the viewfinder applies, built independently with
 * QTransform from what VideoOutput does, so viewToFrame() is checked against
 * the geometry rather than against a copy of itself.
 */
static QPointF frameToView(const QPointF &frameNorm, const QSizeF &view, const QSizeF &frame,
                           int rotation, bool mirrored, qreal zoom)
{
    const QSizeF shown = (rotation % 180) ? frame.transposed() : frame;
    const qreal scale = std::min(view.width() / shown.width(), view.height() / shown.height());
    const QRectF picture(QPointF((view.width() - shown.width() * scale) / 2,
                                 (view.height() - shown.height() * scale) / 2),
                         shown * scale);

    // Frame pixels, turned counter-clockwise about the frame's centre. In
    // y-down coordinates a counter-clockwise turn is a negative angle.
    QTransform t;
    t.translate(shown.width() / 2, shown.height() / 2);
    t.rotate(-rotation);
    t.translate(-frame.width() / 2, -frame.height() / 2);
    QPointF p = t.map(QPointF(frameNorm.x() * frame.width(), frameNorm.y() * frame.height()));
    QPointF norm(p.x() / shown.width(), p.y() / shown.height());
    if (mirrored)
        norm.setX(1.0 - norm.x());
    QPointF onView(picture.left() + norm.x() * picture.width(),
                   picture.top() + norm.y() * picture.height());
    const QPointF centre(view.width() / 2, view.height() / 2);
    return centre + (onView - centre) * zoom;
}

TEST(ViewToFrame, CornersOfAnUprightFrame)
{
    const QSizeF view(400, 300), frame(640, 480);
    EXPECT_EQ(viewToFrame(QPointF(0, 0), view, frame, 0, false), QPointF(0, 0));
    EXPECT_EQ(viewToFrame(QPointF(400, 300), view, frame, 0, false), QPointF(1, 1));
    EXPECT_EQ(viewToFrame(QPointF(200, 150), view, frame, 0, false), QPointF(0.5, 0.5));
}

TEST(ViewToFrame, QuarterTurns)
{
    const QSizeF view(300, 400), frame(640, 480);
    // Turned 90 degrees counter-clockwise the frame's top-right corner is
    // shown top-left.
    EXPECT_EQ(viewToFrame(QPointF(0, 0), view, frame, 90, false), QPointF(1, 0));
    EXPECT_EQ(viewToFrame(QPointF(0, 0), view, frame, 270, false), QPointF(0, 1));
    EXPECT_EQ(viewToFrame(QPointF(0, 0), QSizeF(400, 300), frame, 180, false), QPointF(1, 1));
}

TEST(ViewToFrame, MirroringFlipsWhatIsShown)
{
    const QSizeF view(400, 300), frame(640, 480);
    EXPECT_EQ(viewToFrame(QPointF(0, 0), view, frame, 0, true), QPointF(1, 0));
}

TEST(ViewToFrame, LetterboxBarsAreOutsideThePicture)
{
    // A 4:3 frame in a tall view leaves bars above and below.
    const QSizeF view(300, 600), frame(640, 480);
    EXPECT_EQ(viewToFrame(QPointF(150, 10), view, frame, 0, false), QPointF(-1, -1));
    EXPECT_EQ(viewToFrame(QPointF(150, 300), view, frame, 0, false), QPointF(0.5, 0.5));
}

TEST(ViewToFrame, ZoomKeepsTheCentre)
{
    const QSizeF view(400, 300), frame(640, 480);
    EXPECT_EQ(viewToFrame(QPointF(200, 150), view, frame, 0, false, 4.0), QPointF(0.5, 0.5));
    // At 2x the view's corner shows the frame's quarter point.
    EXPECT_EQ(viewToFrame(QPointF(0, 0), view, frame, 0, false, 2.0), QPointF(0.25, 0.25));
}

TEST(ViewToFrame, RejectsNonsense)
{
    EXPECT_EQ(viewToFrame(QPointF(1, 1), QSizeF(), QSizeF(640, 480), 0, false), QPointF(-1, -1));
    EXPECT_EQ(viewToFrame(QPointF(1, 1), QSizeF(10, 10), QSizeF(640, 480), 45, false), QPointF(-1, -1));
    EXPECT_EQ(viewToFrame(QPointF(1, 1), QSizeF(10, 10), QSizeF(640, 480), 0, false, 0.0), QPointF(-1, -1));
    // Negative and over-full turns are normalised.
    EXPECT_EQ(viewToFrame(QPointF(0, 0), QSizeF(300, 400), QSizeF(640, 480), -270, false),
              viewToFrame(QPointF(0, 0), QSizeF(300, 400), QSizeF(640, 480), 450, false));
}

TEST(ViewToFrame, InvertsTheViewfinderEverywhere)
{
    const QSizeF frame(640, 480);
    const QSizeF views[] = { QSizeF(480, 800), QSizeF(800, 480), QSizeF(720, 720) };
    for (const QSizeF &view : views) {
        for (int rotation : { 0, 90, 180, 270 }) {
            for (bool mirrored : { false, true }) {
                for (qreal zoom : { 1.0, 1.7 }) {
                    for (qreal fx = 0.3; fx <= 0.71; fx += 0.1) {
                        for (qreal fy = 0.3; fy <= 0.71; fy += 0.1) {
                            const QPointF onView = frameToView(QPointF(fx, fy), view, frame,
                                                               rotation, mirrored, zoom);
                            const QPointF back = viewToFrame(onView, view, frame, rotation,
                                                             mirrored, zoom);
                            EXPECT_NEAR(back.x(), fx, 1e-9) << "rotation " << rotation
                                << " mirrored " << mirrored << " zoom " << zoom;
                            EXPECT_NEAR(back.y(), fy, 1e-9) << "rotation " << rotation
                                << " mirrored " << mirrored << " zoom " << zoom;
                        }
                    }
                }
            }
        }
    }
}

/* What gst-droid sends is a whole number of the HAL's steps, the fraction
 * dropped; the EV written into a photo has to be that, not what was asked. */
TEST(AppliedExposure, WholeStepsOfTheHalsStep)
{
    EXPECT_NEAR(CameraControls::appliedExposure(2.0, -2.0, 2.0, 0.2), 2.0, 1e-6);
    EXPECT_NEAR(CameraControls::appliedExposure(0.6, -2.0, 2.0, 0.2), 0.6, 1e-6);
    EXPECT_NEAR(CameraControls::appliedExposure(0.0, -2.0, 2.0, 0.2), 0.0, 1e-6);
    EXPECT_NEAR(CameraControls::appliedExposure(-0.3, -2.0, 2.0, 0.1), -0.3, 1e-6);
}

TEST(AppliedExposure, DropsTheFractionTowardsZero)
{
    // 2.8 and -2.8 steps: the fraction goes, it is not rounded to 3.
    EXPECT_NEAR(CameraControls::appliedExposure(1.4, -2.0, 2.0, 0.5), 1.0, 1e-6);
    EXPECT_NEAR(CameraControls::appliedExposure(-1.4, -2.0, 2.0, 0.5), -1.0, 1e-6);
}

TEST(AppliedExposure, ClampedToTheRange)
{
    EXPECT_NEAR(CameraControls::appliedExposure(5.0, -2.0, 2.0, 0.5), 2.0, 1e-6);
    EXPECT_NEAR(CameraControls::appliedExposure(-5.0, -2.0, 2.0, 0.5), -2.0, 1e-6);
}

TEST(AppliedExposure, NothingWithoutAStep)
{
    EXPECT_EQ(CameraControls::appliedExposure(1.0, -2.0, 2.0, 0.0), 0.0);
    EXPECT_EQ(CameraControls::appliedExposure(1.0, -2.0, 2.0, -0.5), 0.0);
    EXPECT_EQ(CameraControls::appliedExposure(std::nan(""), -2.0, 2.0, 0.5), 0.0);
}

TEST(JpegQuality, WithinDroidcamsrcsRange)
{
    EXPECT_EQ(CameraControls::jpegQuality(85), 85);
    EXPECT_EQ(CameraControls::jpegQuality(100), 100);
    EXPECT_EQ(CameraControls::jpegQuality(10), 10);
    EXPECT_EQ(CameraControls::jpegQuality(0), 10);
    EXPECT_EQ(CameraControls::jpegQuality(150), 100);
    EXPECT_EQ(CameraControls::kDefaultJpegQuality, 90);
}
