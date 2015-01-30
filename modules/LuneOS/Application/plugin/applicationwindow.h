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

#include <QQuickWindow>
#include <QQmlParserStatus>

class ApplicationWindow : public QQuickWindow,
                          public QQmlParserStatus
{
    Q_OBJECT
    Q_ENUMS(Type)
    Q_PROPERTY(Type type READ type WRITE setType)
    Q_PROPERTY(unsigned int windowId READ windowId NOTIFY windowIdChanged)
    Q_PROPERTY(unsigned int parentWindowId READ parentWindowId WRITE setParentWindowId NOTIFY parentWindowIdChanged)
    Q_PROPERTY(bool keepAlive READ keepAlive WRITE setKeepAlive NOTIFY keepAliveChanged)

public:
    explicit ApplicationWindow();

    enum Type {
        Card,
        Dashboard,
        PopupAlert
    };

    Type type() const;
    void setType(Type type);

    unsigned int windowId() const;

    unsigned int parentWindowId() const;
    void setParentWindowId(unsigned int id);

    bool keepAlive() const;
    void setKeepAlive(bool value);

    virtual void classBegin();
    virtual void componentComplete();

public slots:
    void cleanup();

signals:
    void windowIdChanged();
    void parentWindowIdChanged();
    void closed(ApplicationWindow *window);
    void keepAliveChanged();

private slots:
    void onDestroyed();

protected:
    bool eventFilter(QObject *object, QEvent *event);

private:
    Type mType;
    unsigned int mWindowId;
    unsigned int mParentWindowId;
    bool mKeepAlive;
    bool mInitialized;

    void setWindowProperty(const QString &name, const QVariant &value);
};

#endif // APPLICATIONWINDOW_H
