/*
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
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

#include <QQuickWindow>

#include "fpscounter.h"

namespace luna
{

FpsCounter::FpsCounter(QQuickItem *parent) :
    QQuickItem(parent),
    mFrameCounter(0),
    mFps(0)
{
    connect(&mUpdateTimer, &QTimer::timeout, this, &FpsCounter::updateFps);
    connect(this, &QQuickItem::windowChanged, this, &FpsCounter::setWindow);

    mUpdateTimer.setInterval(2000);
    mUpdateTimer.start();

    setWindow(window());
}

FpsCounter::~FpsCounter()
{
    // ~QQuickItem, which runs after this, takes the item out of its window
    // and so emits windowChanged: setWindow() must not run on what is left.
    disconnect(this, &QQuickItem::windowChanged, this, &FpsCounter::setWindow);
    QObject::disconnect(mFrameConnection);
}

void FpsCounter::setWindow(QQuickWindow *newWindow)
{
    // Frames of the window it was in no longer count, and none count after
    // this item is gone: the connection has it as its context.
    QObject::disconnect(mFrameConnection);
    mFrameConnection = QMetaObject::Connection();

    if (newWindow) {
        mFrameConnection = connect(newWindow, &QQuickWindow::frameSwapped, this, [this]() {
            mFrameCounter.fetch_add(1, std::memory_order_relaxed);
        }, Qt::DirectConnection);
    }
}

void FpsCounter::updateFps()
{
    mFps = mFrameCounter.exchange(0, std::memory_order_relaxed) / 2;
    Q_EMIT fpsChanged();
}

unsigned int FpsCounter::fps() const
{
    return mFps;
}

} // namespace luna
