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

#include <QQuickWindow>
#include <QSignalSpy>
#include <QtTest/QTest>

#include "gesturehandler.h"

/*
 * GestureHandler's recognizers watch every touch of the application. The
 * touches here go through Qt as a touch screen's would, so their points carry
 * where they are on the screen and where they were pressed.
 */

namespace
{

QPointingDevice *touchScreen()
{
    static QPointingDevice *device = QTest::createTouchDevice();
    return device;
}

class GestureHandlerTest : public ::testing::Test
{
protected:
    void SetUp() override
    {
        // The edges are the screen's, and the shell's window covers the
        // screen: it is at the screen's left. It is lower than the screen's
        // top, so a position on the screen is not the one in the window.
        window.setGeometry(0, 40, 400, 400);
        window.show();
        ASSERT_TRUE(QTest::qWaitForWindowExposed(&window));
        handler = new luna::GestureHandler(window.contentItem());
        handler->setSize(QSizeF(400, 400));
        handler->setFingerSize(20);
        // timeout and minimalFlickLength as they are unless set: 2000, 100
        spy.reset(new QSignalSpy(handler, &luna::GestureHandler::gestureEvent));
    }

    luna::GestureHandler::GestureType type(int i) const
    {
        return spy->at(i).at(0).value<luna::GestureHandler::GestureType>();
    }
    QPoint pos(int i) const { return spy->at(i).at(1).toPoint(); }
    bool timedOut(int i) const { return spy->at(i).at(2).toBool(); }

    QQuickWindow window;
    luna::GestureHandler *handler = nullptr;
    std::unique_ptr<QSignalSpy> spy;
};

}

TEST(GestureHandler, aFlickWaitsTwoSecondsAndIsAHundredLongUnlessSetOtherwise)
{
    luna::GestureHandler handler;
    EXPECT_EQ(handler.property("timeout").toInt(), 2000);
    EXPECT_EQ(handler.property("minimalFlickLength").toReal(), 100);
}

TEST_F(GestureHandlerTest, anEdgeTouchHeldIsAFlickThatTimedOut)
{
    handler->setTimeout(50);
    QTest::touchEvent(&window, touchScreen()).press(0, QPoint(5, 200), &window);
    EXPECT_EQ(spy->count(), 0);
    ASSERT_TRUE(spy->wait(1000));
    EXPECT_EQ(type(0), luna::GestureHandler::ScreenEdgeFlickGesture);
    EXPECT_EQ(pos(0), window.mapToGlobal(QPoint(5, 200)));
    EXPECT_TRUE(timedOut(0));
    QTest::touchEvent(&window, touchScreen()).release(0, QPoint(5, 200), &window);
}

TEST_F(GestureHandlerTest, aTapIsWhereItIsOnTheScreen)
{
    QTest::touchEvent(&window, touchScreen()).press(0, QPoint(150, 160), &window);
    QTest::touchEvent(&window, touchScreen()).release(0, QPoint(150, 160), &window);
    ASSERT_EQ(spy->count(), 1);
    EXPECT_EQ(type(0), luna::GestureHandler::TapGesture);
    EXPECT_EQ(pos(0), window.mapToGlobal(QPoint(150, 160)));
    EXPECT_FALSE(timedOut(0));
}

TEST_F(GestureHandlerTest, aTouchThatMovesMoreThanAFingerIsNoTap)
{
    QTest::touchEvent(&window, touchScreen()).press(0, QPoint(150, 160), &window);
    QTest::touchEvent(&window, touchScreen()).move(0, QPoint(150, 190), &window);
    QTest::touchEvent(&window, touchScreen()).release(0, QPoint(150, 190), &window);
    EXPECT_EQ(spy->count(), 0);
}

TEST_F(GestureHandlerTest, aTouchThatStaysWithinAFingerIsATap)
{
    QTest::touchEvent(&window, touchScreen()).press(0, QPoint(150, 160), &window);
    QTest::touchEvent(&window, touchScreen()).move(0, QPoint(150, 175), &window);
    QTest::touchEvent(&window, touchScreen()).release(0, QPoint(150, 175), &window);
    ASSERT_EQ(spy->count(), 1);
    EXPECT_EQ(type(0), luna::GestureHandler::TapGesture);
    EXPECT_EQ(pos(0), window.mapToGlobal(QPoint(150, 175)));
}

TEST_F(GestureHandlerTest, aFlickFromTheEdgeIsAnEdgeFlickFromWhereItBegan)
{
    QTest::touchEvent(&window, touchScreen()).press(0, QPoint(5, 200), &window);
    QTest::touchEvent(&window, touchScreen()).move(0, QPoint(80, 205), &window);
    QTest::touchEvent(&window, touchScreen()).release(0, QPoint(150, 205), &window);
    ASSERT_EQ(spy->count(), 1);
    EXPECT_EQ(type(0), luna::GestureHandler::ScreenEdgeFlickGesture);
    EXPECT_EQ(pos(0), window.mapToGlobal(QPoint(5, 200)));
    EXPECT_FALSE(timedOut(0));
}

TEST_F(GestureHandlerTest, aShortFlickFromTheEdgeIsNoFlick)
{
    QTest::touchEvent(&window, touchScreen()).press(0, QPoint(5, 200), &window);
    QTest::touchEvent(&window, touchScreen()).move(0, QPoint(50, 200), &window);
    QTest::touchEvent(&window, touchScreen()).release(0, QPoint(60, 200), &window);
    EXPECT_EQ(spy->count(), 0);
}

TEST_F(GestureHandlerTest, aFlickAlongTheEdgeIsNoEdgeFlick)
{
    QTest::touchEvent(&window, touchScreen()).press(0, QPoint(5, 100), &window);
    QTest::touchEvent(&window, touchScreen()).move(0, QPoint(10, 200), &window);
    QTest::touchEvent(&window, touchScreen()).release(0, QPoint(10, 300), &window);
    EXPECT_EQ(spy->count(), 0);
}

TEST_F(GestureHandlerTest, aFlickInTheMiddleIsNoEdgeFlick)
{
    QTest::touchEvent(&window, touchScreen()).press(0, QPoint(200, 200), &window);
    QTest::touchEvent(&window, touchScreen()).move(0, QPoint(260, 200), &window);
    QTest::touchEvent(&window, touchScreen()).release(0, QPoint(350, 200), &window);
    EXPECT_EQ(spy->count(), 0);
}

TEST_F(GestureHandlerTest, aFlickIsMeasuredOnTheScreen)
{
    // From (5, 240) to (95, 200) on the screen is less than 100; from the
    // start on the screen to (95, 160) in the window it would be 120.
    QTest::touchEvent(&window, touchScreen()).press(0, QPoint(5, 200), &window);
    QTest::touchEvent(&window, touchScreen()).move(0, QPoint(50, 180), &window);
    QTest::touchEvent(&window, touchScreen()).release(0, QPoint(95, 160), &window);
    EXPECT_EQ(spy->count(), 0);
}
