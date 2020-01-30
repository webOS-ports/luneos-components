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

#ifndef APPLICATIONWINDOW_H
#define APPLICATIONWINDOW_H

#include <QtQuickTemplates2/private/qquickapplicationwindow_p.h>

class LuneOSWindow : public QQuickApplicationWindow
{
    Q_OBJECT

    Q_PROPERTY(Type type READ type WRITE setType)
    Q_PROPERTY(unsigned int windowId READ windowId NOTIFY windowIdChanged)
    Q_PROPERTY(unsigned int parentWindowId READ parentWindowId WRITE setParentWindowId NOTIFY parentWindowIdChanged)
    Q_PROPERTY(bool keepAlive READ keepAlive WRITE setKeepAlive NOTIFY keepAliveChanged)
    Q_PROPERTY(bool loadingAnimationDisabled READ loadingAnimationDisabled WRITE setLoadingAnimationDisabled NOTIFY loadingAnimationDisabledChanged)
    QML_ELEMENT

public:
    explicit LuneOSWindow();

    enum Type {
        Card,
        Launcher,
        Dashboard,
        PopupAlert,
        BannerAlert,
        Overlay,
        Pin,
    };
    Q_ENUM(Type)

    Type type() const;
    void setType(Type type);

    unsigned int windowId() const;

    unsigned int parentWindowId() const;
    void setParentWindowId(unsigned int id);

    bool keepAlive() const;
    void setKeepAlive(bool value);

    bool loadingAnimationDisabled() const;
    void setLoadingAnimationDisabled(bool value);

public Q_SLOTS:
    void cleanup();
    void show();

Q_SIGNALS:
    void windowIdChanged();
    void parentWindowIdChanged();
    void closed(LuneOSWindow *window);
    void keepAliveChanged();
    void loadingAnimationDisabledChanged();

private Q_SLOTS:
    void onDestroyed();
    void onWindowPropertyChanged(QPlatformWindow *window, const QString &name);

protected:;
    bool eventFilter(QObject *object, QEvent *event);

private:
    Type mType;
    unsigned int mWindowId;
    unsigned int mParentWindowId;
    bool mKeepAlive;
    bool mInitialized;
    bool mLoadingAnimationDisabled;

    void setWindowProperty(const QString &name, const QVariant &value);
    QVariant getWindowProperty(const QString &name);

    void configure();
    void reset();
};
    
QML_DECLARE_TYPEINFO(LuneOSWindow, QML_HAS_ATTACHED_PROPERTIES)

#endif // APPLICATIONWINDOW_H
