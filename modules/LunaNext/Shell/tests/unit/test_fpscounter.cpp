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

#include <cstring>
#include <new>
#include <thread>

#include <QQuickWindow>

#include "fpscounter.h"

using luna::FpsCounter;

namespace
{

/* What the 2 s timer does, at once. */
unsigned int tick(FpsCounter *counter)
{
    EXPECT_TRUE(QMetaObject::invokeMethod(counter, "updateFps"));
    return counter->fps();
}

void swapFrames(QQuickWindow &window, int frames)
{
    for (int i = 0; i < frames; i++)
        Q_EMIT window.frameSwapped();
}

}

TEST(FpsCounter, startsAtZero)
{
    // Built over memory that is not zero, so a counter left out shows.
    alignas(FpsCounter) unsigned char memory[sizeof(FpsCounter)];
    std::memset(memory, 0xa5, sizeof(memory));
    FpsCounter *counter = new (memory) FpsCounter;
    EXPECT_EQ(counter->fps(), 0u);
    EXPECT_EQ(tick(counter), 0u);
    counter->~FpsCounter();
}

TEST(FpsCounter, countsTheFramesOfItsWindow)
{
    QQuickWindow window;
    FpsCounter *counter = new FpsCounter(window.contentItem());
    swapFrames(window, 10);
    EXPECT_EQ(tick(counter), 5u);
    EXPECT_EQ(tick(counter), 0u);
}

TEST(FpsCounter, countsOnlyTheWindowItIsIn)
{
    QQuickWindow first, second;
    FpsCounter *counter = new FpsCounter(first.contentItem());
    counter->setParentItem(second.contentItem());
    swapFrames(first, 10);
    EXPECT_EQ(tick(counter), 0u);
    swapFrames(second, 6);
    EXPECT_EQ(tick(counter), 3u);
}

TEST(FpsCounter, aWindowOutlivingItCountsNothingMore)
{
    // The counter went before its window; the window's next frame wrote
    // into it.
    QQuickWindow window;
    FpsCounter *counter = new FpsCounter(window.contentItem());
    delete counter;
    swapFrames(window, 3);
}

TEST(FpsCounter, framesFromTheRenderThreadAreCounted)
{
    // The threaded render loop swaps on its own thread while the timer
    // reads on this one (ThreadSanitizer reports the race if it is back).
    QQuickWindow window;
    FpsCounter *counter = new FpsCounter(window.contentItem());
    std::thread render([&window]() { swapFrames(window, 2000); });
    unsigned int counted = 0;
    for (int i = 0; i < 50; i++)
        counted += tick(counter) * 2;
    render.join();
    counted += tick(counter) * 2;
    // Each reading drops at most one odd frame.
    EXPECT_LE(counted, 2000u);
    EXPECT_GE(counted, 2000u - 51u);
}
