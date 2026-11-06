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

#include <QObject>
#include <QQuickItem>
#include <QQuickWindow>
#include <QTouchEvent>
#include <QtTest/QTest>
#include <private/qeventpoint_p.h>

#include "inversemouseareatype.h"

namespace
{

/* The touch events InverseMouseArea filters from the window, handed to
 * its filter directly. */
class Probe : public InverseMouseAreaType
{
public:
    using InverseMouseAreaType::InverseMouseAreaType;
    bool filter(QObject *target, QEvent *event) { return eventFilter(target, event); }
};

QPointingDevice *touchScreen()
{
    static QPointingDevice *device = QTest::createTouchDevice();
    return device;
}

QTouchEvent touch(QEvent::Type type, int id, QEventPoint::State state, QPointF pos)
{
    QEventPoint point(id, state, pos, pos);
    return QTouchEvent(type, touchScreen(), Qt::NoModifier, QList<QEventPoint>() << point);
}

/* A touch as it reaches an item: its points carry their position in that
 * item as well as in the scene. */
QTouchEvent touchAt(QEvent::Type type, int id, QEventPoint::State state, QPointF local, QPointF scene)
{
    QEventPoint point(id, state, scene, scene);
    QMutableEventPoint::setPosition(point, local);
    return QTouchEvent(type, touchScreen(), Qt::NoModifier, QList<QEventPoint>() << point);
}

class InverseMouseAreaTest : public ::testing::Test
{
protected:
    void SetUp() override
    {
        window.resize(200, 200);
        window.contentItem()->setSize(QSizeF(200, 200));
        // The first item of the window is what InverseMouseArea senses in.
        background = new QQuickItem(window.contentItem());
        background->setSize(QSizeF(200, 200));
        area = new Probe(window.contentItem());
        area->setSize(QSizeF(100, 100));
    }

    QQuickWindow window;
    QQuickItem *background = nullptr;
    Probe *area = nullptr;
};

}

TEST_F(InverseMouseAreaTest, touchEndWithoutItsBeginPassesThrough)
{
    // The touch began before the filter was there: no release to map.
    QTouchEvent end = touch(QEvent::TouchEnd, 7, QEventPoint::State::Released, QPointF(150, 150));
    EXPECT_FALSE(area->filter(window.contentItem(), &end));
}

TEST_F(InverseMouseAreaTest, touchEndOfAnotherFingerPassesThrough)
{
    QTouchEvent begin = touch(QEvent::TouchBegin, 1, QEventPoint::State::Pressed, QPointF(150, 150));
    area->filter(window.contentItem(), &begin);
    EXPECT_TRUE(area->isPressed());

    QTouchEvent other = touch(QEvent::TouchEnd, 2, QEventPoint::State::Released, QPointF(150, 150));
    EXPECT_FALSE(area->filter(window.contentItem(), &other));
    EXPECT_TRUE(area->isPressed());

    // The finger that began it ends the press.
    QTouchEvent end = touch(QEvent::TouchEnd, 1, QEventPoint::State::Released, QPointF(150, 150));
    area->filter(window.contentItem(), &end);
    EXPECT_FALSE(area->isPressed());
}

TEST_F(InverseMouseAreaTest, touchOnSomethingThatIsNoItemPassesThrough)
{
    // Nothing to map the points through.
    QObject plain;
    QTouchEvent begin = touch(QEvent::TouchBegin, 1, QEventPoint::State::Pressed, QPointF(150, 150));
    EXPECT_FALSE(area->filter(&plain, &begin));
    QTouchEvent end = touch(QEvent::TouchEnd, 1, QEventPoint::State::Released, QPointF(150, 150));
    EXPECT_FALSE(area->filter(&plain, &end));
}

TEST(InverseMouseArea, firstItemOfItsWindowSensesTheWindow)
{
    // With nothing before it, the area is its own sensing area; asking
    // whether it contains a point asked itself again until the stack ran out.
    QQuickWindow window;
    window.resize(200, 200);
    window.contentItem()->setSize(QSizeF(200, 200));
    Probe *area = new Probe(window.contentItem());
    area->setSize(QSizeF(100, 100));
    EXPECT_FALSE(area->contains(QPointF(50, 50)));
    EXPECT_TRUE(area->contains(QPointF(150, 150)));
    EXPECT_FALSE(area->contains(QPointF(250, 250)));
}

TEST_F(InverseMouseAreaTest, containsWhatIsOutsideItInItsSensingArea)
{
    EXPECT_FALSE(area->contains(QPointF(50, 50)));
    EXPECT_TRUE(area->contains(QPointF(150, 150)));
    EXPECT_FALSE(area->contains(QPointF(250, 250)));
}

TEST(InverseMouseArea, destroyedInItsWindowLeavesItAlone)
{
    // Taken out of the window as its QQuickItem part went, it updated its
    // event filter from the part already destroyed (AddressSanitizer saw
    // what that left). The window filters no events for it after.
    QQuickWindow window;
    window.resize(200, 200);
    {
        Probe area(window.contentItem());
        area.setSize(QSizeF(100, 100));
        ASSERT_TRUE(area.setProperty("topmostItem", true));
    }
    QTouchEvent begin = touch(QEvent::TouchBegin, 1, QEventPoint::State::Pressed, QPointF(150, 150));
    QCoreApplication::sendEvent(&window, &begin);
}

TEST_F(InverseMouseAreaTest, aTouchOutsideItLandsWhereItWasInTheArea)
{
    // The area is not at the window's origin: the touch's scene position is
    // mapped into the area's own coordinates.
    area->setPosition(QPointF(20, 30));
    // The area filters the window's events; in a window a point's position
    // is its scene position.
    QTouchEvent begin = touchAt(QEvent::TouchBegin, 1, QEventPoint::State::Pressed, QPointF(150, 160), QPointF(150, 160));
    area->filter(&window, &begin);
    EXPECT_TRUE(area->isPressed());
    EXPECT_EQ(area->mouseX(), 130);
    EXPECT_EQ(area->mouseY(), 130);

    QTouchEvent move = touchAt(QEvent::TouchUpdate, 1, QEventPoint::State::Updated, QPointF(170, 190), QPointF(170, 190));
    area->filter(&window, &move);
    EXPECT_EQ(area->mouseX(), 150);
    EXPECT_EQ(area->mouseY(), 160);

    QTouchEvent end = touchAt(QEvent::TouchEnd, 1, QEventPoint::State::Released, QPointF(180, 200), QPointF(180, 200));
    area->filter(&window, &end);
    EXPECT_FALSE(area->isPressed());
    EXPECT_EQ(area->mouseX(), 160);
    EXPECT_EQ(area->mouseY(), 170);
}

TEST_F(InverseMouseAreaTest, aTouchOnAnItemInsideIsMappedThroughThatItem)
{
    // The points of a touch are the item's own: they go through the scene.
    area->setPosition(QPointF(20, 30));
    background->setPosition(QPointF(10, 10));
    QTouchEvent begin = touchAt(QEvent::TouchBegin, 1, QEventPoint::State::Pressed, QPointF(140, 150), QPointF(150, 160));
    area->filter(background, &begin);
    EXPECT_EQ(area->mouseX(), 130);
    EXPECT_EQ(area->mouseY(), 130);

    QTouchEvent end = touchAt(QEvent::TouchEnd, 1, QEventPoint::State::Released, QPointF(150, 170), QPointF(160, 180));
    area->filter(background, &end);
    EXPECT_FALSE(area->isPressed());
    EXPECT_EQ(area->mouseX(), 140);
    EXPECT_EQ(area->mouseY(), 150);
}

TEST_F(InverseMouseAreaTest, aMousePressOutsideItLandsWhereItWasInTheArea)
{
    area->setPosition(QPointF(20, 30));
    const QPointF scene(150, 160);
    QMouseEvent press(QEvent::MouseButtonPress, scene, scene, QPointF(1150, 1160),
                      Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
    area->filter(window.contentItem(), &press);
    EXPECT_TRUE(area->isPressed());
    EXPECT_EQ(area->mouseX(), 130);
    EXPECT_EQ(area->mouseY(), 130);
}

TEST_F(InverseMouseAreaTest, aHoverOutsideItLandsWhereItWasInTheArea)
{
    area->setPosition(QPointF(20, 30));
    area->setHoverEnabled(true);
    QHoverEvent enter(QEvent::HoverEnter, QPointF(150, 160), QPointF(150, 160), QPointF(150, 160));
    area->filter(window.contentItem(), &enter);
    QHoverEvent move(QEvent::HoverMove, QPointF(160, 180), QPointF(160, 180), QPointF(150, 160));
    area->filter(window.contentItem(), &move);
    EXPECT_TRUE(area->hovered());
    EXPECT_EQ(area->mouseX(), 140);
    EXPECT_EQ(area->mouseY(), 150);
}
