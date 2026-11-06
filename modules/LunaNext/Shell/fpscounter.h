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

#ifndef FPSCOUNTER_H_
#define FPSCOUNTER_H_

#include <QObject>
#include <QQuickItem>
#include <QTimer>

#include <atomic>

namespace luna
{

class FpsCounter : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(unsigned int fps READ fps NOTIFY fpsChanged)

public:
    explicit FpsCounter(QQuickItem *parent = 0);
    ~FpsCounter() override;

    unsigned int fps() const;

signals:
    void fpsChanged();

private slots:
    void setWindow(QQuickWindow *newWindow);
    void updateFps();

private:
    // Counted where the window swaps its frames, which is the render
    // thread under the threaded render loop, and read here.
    std::atomic<unsigned int> mFrameCounter;
    unsigned int mFps;
    QTimer mUpdateTimer;
    QMetaObject::Connection mFrameConnection;
};

} // namespace luna

#endif
