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

#include "applicationwindow.h"

QString windowTypeToString(ApplicationWindow::Type type)
{
    QString typeStr;

    switch (type) {
    case ApplicationWindow::Card:
        typeStr = "card";
        break;
    case ApplicationWindow::Dashboard:
        typeStr = "dashboard";
        break;
    case ApplicationWindow::PopupAlert:
        typeStr = "popupalert";
        break;
    default:
        break;
    }

    return typeStr;
}

ApplicationWindow::ApplicationWindow() :
    mType(ApplicationWindow::Card),
    mWindowId(0),
    mParentWindowId(0),
    mKeepAlive(false),
    mInitialized(false),
    mLoadingAnimationDisabled(false)
{
    installEventFilter(this);

    connect(this, SIGNAL(destroyed()), this, SLOT(onDestroyed()));
}

void ApplicationWindow::classBegin()
{
}

void ApplicationWindow::setWindowProperty(const QString &name, const QVariant &value)
{
    QPlatformNativeInterface *nativeInterface = QGuiApplication::platformNativeInterface();
    nativeInterface->setWindowProperty(handle(), name, value);
}

void ApplicationWindow::componentComplete()
{
    qDebug() << Q_FUNC_INFO << "type" << mType;
}

void ApplicationWindow::show()
{
    qDebug() << Q_FUNC_INFO << "initialized" << mInitialized;

    if (!mInitialized) {
        configure();
        mInitialized = true;
    }

    QQuickWindow::show();
}

void ApplicationWindow::configure()
{
    // Make sure the platform window is fully created when we want to deal with it
    create();

    // set different information bits for our window
    setWindowProperty(QString("_LUNE_WINDOW_TYPE"), QVariant(windowTypeToString(mType)));
    setWindowProperty(QString("_LUNE_WINDOW_LOADING_ANIMATION_DISABLED"), QVariant(mLoadingAnimationDisabled));
    setWindowProperty(QString("_LUNE_APP_ID"), QVariant(QCoreApplication::applicationName()));
    setWindowProperty(QString("_LUNE_APP_KEEP_ALIVE"), QVariant(mKeepAlive));
}

bool ApplicationWindow::eventFilter(QObject *object, QEvent *event)
{
    Q_UNUSED(object);

    switch (event->type()) {
    case QEvent::Close:
        Q_EMIT closed(this);
        mInitialized = false;
        break;
    default:
        break;
    }

    return false;
}

void ApplicationWindow::cleanup()
{
    close();
    destroy();
}

void ApplicationWindow::onDestroyed()
{
    qDebug() << Q_FUNC_INFO;
}

void ApplicationWindow::setType(Type type)
{
    mType = type;
}

ApplicationWindow::Type ApplicationWindow::type() const
{
    return mType;
}

void ApplicationWindow::setParentWindowId(unsigned int id)
{
    if (mParentWindowId == id)
        return;

    mParentWindowId = id;
    Q_EMIT parentWindowIdChanged();
}

unsigned int ApplicationWindow::parentWindowId() const
{
    return mParentWindowId;
}

unsigned int ApplicationWindow::windowId() const
{
    return mWindowId;
}

bool ApplicationWindow::keepAlive() const
{
    return mKeepAlive;
}

void ApplicationWindow::setKeepAlive(bool value)
{
    if (mKeepAlive == value)
        return;

    mKeepAlive = value;

    if (!mInitialized)
        return;

    setWindowProperty(QString("_LUNE_WINDOW_KEEP_ALIVE"), QVariant(mKeepAlive));
    Q_EMIT keepAliveChanged();
}

bool ApplicationWindow::loadingAnimationDisabled() const
{
    return mLoadingAnimationDisabled;
}

void ApplicationWindow::setLoadingAnimationDisabled(bool value)
{
    if (mLoadingAnimationDisabled == value)
        return;

    mLoadingAnimationDisabled = value;

    if (!mInitialized)
        return;

    setWindowProperty(QString("_LUNE_WINDOW_LOADING_ANIMATION_DISABLED"), QVariant(mLoadingAnimationDisabled));
    Q_EMIT loadingAnimationDisabledChanged();
}
