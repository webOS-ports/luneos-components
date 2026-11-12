/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2016 Nikolay Nizov <nizovn@gmail.com>
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

#include <QGuiApplication>
#include <QTouchEvent>
#include <QLineF>

#include "gesturehandler.h"

namespace luna
{

// maximum tangent of angle between flick direction and perpendicular to screen edge
#define FLICK_MAX_TAN 0.5

GestureHandler::GestureHandler(QQuickItem *parent) :
    QQuickItem(parent),
    mFingerSize(0),
    mMinFlick(100),
    mTimeout(2000)
{
    mTapRecognizer = new TapGestureRecognizer(this);
    mScreenEdgeFlickRecognizer = new ScreenEdgeFlickGestureRecognizer(this);
    // The recognizer's timer has no interval until it is given one: without
    // this an edge touch timed out at once when the timeout was not set.
    mScreenEdgeFlickRecognizer->setTimeout(mTimeout);
    mScreenEdgeFlickRecognizer->setMinimalFlickLength(mMinFlick);
    connect(mTapRecognizer, &TapGestureRecognizer::tapGesture,
        this, &GestureHandler::gestureEvent);
    connect(mScreenEdgeFlickRecognizer, &ScreenEdgeFlickGestureRecognizer::screenEdgeFlickGesture,
        this, &GestureHandler::gestureEvent);
    connect(mScreenEdgeFlickRecognizer, SIGNAL(touchBegin()),
        this, SIGNAL(touchBegin()));
    connect(mScreenEdgeFlickRecognizer, SIGNAL(touchEnd()),
        this, SIGNAL(touchEnd()));
}

GestureHandler::~GestureHandler()
{
    mTapRecognizer->deleteLater();
    mScreenEdgeFlickRecognizer->deleteLater();
}

void GestureHandler::setFingerSize(qreal size) {
    mFingerSize = size;
    mTapRecognizer->setFingerSize(size);
    mScreenEdgeFlickRecognizer->setFingerSize(size);
}

void GestureHandler::setTimeout(int timeout) {
    mTimeout = timeout;
    mScreenEdgeFlickRecognizer->setTimeout(timeout);
}

void GestureHandler::setMinimalFlickLength(qreal length) {
    mMinFlick = length;
    mScreenEdgeFlickRecognizer->setMinimalFlickLength(length);
}

TapGestureRecognizer::TapGestureRecognizer(QQuickItem *parent) :
    QQuickItem(parent),
    mFingerSize(0)
{
    qApp->installEventFilter(this);
}

bool TapGestureRecognizer::eventFilter(QObject *, QEvent *event)
{
    static bool show = true;
    switch (event->type()) {
    case QEvent::TouchBegin:
        show = true;
        break;
    case QEvent::TouchUpdate:
        {
            QTouchEvent *touchEvent = static_cast<QTouchEvent *>(event);
            const QTouchEvent::TouchPoint &touchPoint = touchEvent->points().first();

            if (QLineF(touchPoint.position(),touchPoint.pressPosition()).length() > mFingerSize)
                show = false;
        }
        break;
    case QEvent::TouchCancel:
        show = false;
        break;
    case QEvent::TouchEnd:
        {
            if (show) {
                QTouchEvent *touchEvent = static_cast<QTouchEvent *>(event);
                const QTouchEvent::TouchPoint &touchPoint = touchEvent->points().first();
                QPointF fpoint = touchPoint.globalPosition();
                emit tapGesture(GestureHandler::TapGesture, fpoint.toPoint(), false);
            };
            show = false;
        }
        break;
    default: break;
    }
    return false;
}

ScreenEdgeFlickGestureRecognizer::ScreenEdgeFlickGestureRecognizer(QQuickItem *parent) :
    QQuickItem(parent),
    mFingerSize(0),
    mMinFlick(100)
{
    qApp->installEventFilter(this);
    mTimer.setSingleShot(true);
    connect(&mTimer, SIGNAL(timeout()), this, SLOT(slotTimeout()));
}

void ScreenEdgeFlickGestureRecognizer::endEdgeTouch()
{
    if (!mEdgeTouch)
        return;
    mEdgeTouch = false;
    emit touchEnd();
}

void ScreenEdgeFlickGestureRecognizer::slotTimeout()
{
    emit screenEdgeFlickGesture(GestureHandler::ScreenEdgeFlickGesture, mStartPos, true);
}

bool ScreenEdgeFlickGestureRecognizer::eventFilter(QObject *, QEvent *event)
{
    switch (event->type()) {
    case QEvent::TouchBegin:
        {
            QTouchEvent *touchEvent = static_cast<QTouchEvent *>(event);
            mTimer.stop();
            endEdgeTouch();
            if (touchEvent->points().count() != 1)
                break;

            const QTouchEvent::TouchPoint &touchPoint = touchEvent->points().first();
            QPointF fpoint = touchPoint.globalPosition();
            mStartPos = fpoint.toPoint();
            QMargins marg(mFingerSize, mFingerSize, mFingerSize, mFingerSize);
            QRect margRect = QRect(0, 0, parentItem()->width(), parentItem()->height()).marginsRemoved(marg);
            if (!margRect.contains(mStartPos)) {
                mTimer.start();
                // Only a touch that can become an edge flick is announced:
                // the shell holds the rotation for it, so that the edges do
                // not move under the finger. A touch in the middle of the
                // screen - a thumb holding the phone, or the Titan's keyboard
                // surface, which kbdscroll feeds in as a drag across the
                // middle - must not stop the screen turning.
                mEdgeTouch = true;
                emit touchBegin();
            }
        }
        break;
    case QEvent::TouchUpdate:
        {
            if (mTimer.isActive()) {
                QTouchEvent *touchEvent = static_cast<QTouchEvent *>(event);
                const QTouchEvent::TouchPoint &touchPoint = touchEvent->points().first();
                QPointF fpoint = touchPoint.globalPosition();
                int x0 = mStartPos.x();
                int y0 = mStartPos.y();
                double deltaX = qAbs(fpoint.x() - x0);
                double deltaY = qAbs(fpoint.y() - y0);

                if ((y0 < mFingerSize) || (y0 > parentItem()->height()-mFingerSize)) {
                    if (((deltaY <= mFingerSize) && (deltaX > mFingerSize)) ||
                        ((deltaY > mFingerSize) && (deltaX/deltaY > FLICK_MAX_TAN)))
                        mTimer.stop();
                }
                else
                if ((x0 < mFingerSize) || (x0 > parentItem()->width()-mFingerSize)) {
                    if (((deltaX <= mFingerSize) && (deltaY > mFingerSize)) ||
                        ((deltaX > mFingerSize) && (deltaY/deltaX > FLICK_MAX_TAN)))
                        mTimer.stop();
                }
            }
        }
        break;
    case QEvent::TouchCancel:
        {
            mTimer.stop();
            endEdgeTouch();
        }
        break;
    case QEvent::TouchEnd:
        {
            QTouchEvent *touchEvent = static_cast<QTouchEvent *>(event);

            if (mTimer.isActive()) {
                mTimer.stop();
                const QTouchEvent::TouchPoint &touchPoint = touchEvent->points().first();
                QPointF fpoint = touchPoint.globalPosition();
                if (QLineF(mStartPos,fpoint).length() >= mMinFlick)
                    emit screenEdgeFlickGesture(GestureHandler::ScreenEdgeFlickGesture, mStartPos, false);
            }
            // TouchEnd marks the end of the whole touch sequence, so it ends
            // an edge touch however it went. A short one (a tap near the
            // edge) used to leave here before this, and the shell's rotation
            // stayed held until its five-second failsafe.
            endEdgeTouch();
        }
        break;
    default: break;
    }
    return false;
}

} // namespace luna
