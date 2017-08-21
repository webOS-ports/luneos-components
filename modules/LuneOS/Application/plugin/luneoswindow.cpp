/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QDebug>
#include <QGuiApplication>
#include <QtGui/qpa/qplatformnativeinterface.h>

#include "luneoswindow.h"

QString windowTypeToString(LuneOSWindow::Type type)
{
    QString typeStr;

    switch (type) {
    case LuneOSWindow::Card:
        typeStr = "card";
        break;
    case LuneOSWindow::Dashboard:
        typeStr = "dashboard";
        break;
    case LuneOSWindow::PopupAlert:
        typeStr = "popupalert";
        break;
    case LuneOSWindow::Pin:
        typeStr = "pin";
        break;
    default:
        break;
    }

    return typeStr;
}

LuneOSWindow::LuneOSWindow() :
    mType(LuneOSWindow::Card),
    mWindowId(0),
    mParentWindowId(0),
    mKeepAlive(false),
    mInitialized(false),
    mLoadingAnimationDisabled(false)
{
    installEventFilter(this);

    connect(this, SIGNAL(destroyed()), this, SLOT(onDestroyed()));
}

void LuneOSWindow::setWindowProperty(const QString &name, const QVariant &value)
{
    QPlatformNativeInterface *nativeInterface = QGuiApplication::platformNativeInterface();
    nativeInterface->setWindowProperty(handle(), name, value);
}

void LuneOSWindow::show()
{
    qDebug() << Q_FUNC_INFO << "initialized" << mInitialized;

    if (!mInitialized) {
        configure();
        mInitialized = true;
    }

    QQuickWindow::show();
}

void LuneOSWindow::configure()
{
    // Make sure the platform window is fully created when we want to deal with it
    create();

    // set different information bits for our window
    setWindowProperty(QString("_LUNE_WINDOW_TYPE"), QVariant(windowTypeToString(mType)));
    setWindowProperty(QString("_LUNE_WINDOW_LOADING_ANIMATION_DISABLED"), QVariant(mLoadingAnimationDisabled));
    setWindowProperty(QString("_LUNE_WINDOW_PARENT_ID"), QVariant(mParentWindowId));
    setWindowProperty(QString("_LUNE_APP_ID"), QVariant(QCoreApplication::applicationName()));
    setWindowProperty(QString("_LUNE_APP_KEEP_ALIVE"), QVariant(mKeepAlive));

    QPlatformNativeInterface *nativeInterface = QGuiApplication::platformNativeInterface();
    connect(nativeInterface, SIGNAL(windowPropertyChanged(QPlatformWindow*, const QString&)),
            this, SLOT(onWindowPropertyChanged(QPlatformWindow*, const QString&)));
}

void LuneOSWindow::reset()
{
    mInitialized = false;

    mWindowId = 0;
    mParentWindowId = 0;

    Q_EMIT windowIdChanged();
    Q_EMIT parentWindowIdChanged();
}

QVariant LuneOSWindow::getWindowProperty(const QString &name)
{
    QPlatformNativeInterface *nativeInterface = QGuiApplication::platformNativeInterface();
    return nativeInterface->windowProperty(handle(), name);
}

void LuneOSWindow::onWindowPropertyChanged(QPlatformWindow *window, const QString &name)
{
    if (window != handle())
        return;

    if (name == "_LUNE_WINDOW_ID") {
        unsigned int windowId = getWindowProperty("_LUNE_WINDOW_ID").toUInt();
        if (windowId != mWindowId) {
            mWindowId = windowId;
            Q_EMIT windowIdChanged();
        }
    }
}

bool LuneOSWindow::eventFilter(QObject *object, QEvent *event)
{
    Q_UNUSED(object);

    switch (event->type()) {
    case QEvent::Close:
        Q_EMIT closed(this);
        reset();
        break;
    default:
        break;
    }

    return QQuickApplicationWindow::eventFilter(object, event);
}

void LuneOSWindow::cleanup()
{
    close();
    destroy();
}

void LuneOSWindow::onDestroyed()
{
    qDebug() << Q_FUNC_INFO;
}

void LuneOSWindow::setType(Type type)
{
    mType = type;
}

LuneOSWindow::Type LuneOSWindow::type() const
{
    return mType;
}

void LuneOSWindow::setParentWindowId(unsigned int id)
{
    if (mParentWindowId == id)
        return;

    mParentWindowId = id;
    Q_EMIT parentWindowIdChanged();
}

unsigned int LuneOSWindow::parentWindowId() const
{
    return mParentWindowId;
}

unsigned int LuneOSWindow::windowId() const
{
    return mWindowId;
}

bool LuneOSWindow::keepAlive() const
{
    return mKeepAlive;
}

void LuneOSWindow::setKeepAlive(bool value)
{
    if (mKeepAlive == value)
        return;

    mKeepAlive = value;

    if (!mInitialized)
        return;

    setWindowProperty(QString("_LUNE_WINDOW_KEEP_ALIVE"), QVariant(mKeepAlive));
    Q_EMIT keepAliveChanged();
}

bool LuneOSWindow::loadingAnimationDisabled() const
{
    return mLoadingAnimationDisabled;
}

void LuneOSWindow::setLoadingAnimationDisabled(bool value)
{
    if (mLoadingAnimationDisabled == value)
        return;

    mLoadingAnimationDisabled = value;

    if (!mInitialized)
        return;

    setWindowProperty(QString("_LUNE_WINDOW_LOADING_ANIMATION_DISABLED"), QVariant(mLoadingAnimationDisabled));
    Q_EMIT loadingAnimationDisabledChanged();
}
