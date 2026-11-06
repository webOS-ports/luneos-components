/*
 * Copyright (C) 2017 Christophe Chapuis <chris.chapuis@gmail.com>
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

#ifndef LUNEOSBTREQUEST_H
#define LUNEOSBTREQUEST_H

#include <bluezqt/agent.h>
#include <bluezqt/device.h>
#include <bluezqt/request.h>

#include <QVariant>

using namespace BluezQt;

/*
 * One request of BlueZ's to the agent, as QML answers it. It is answered
 * once: what comes after the first accept, reject or cancel is ignored. One
 * that goes unanswered (the agent replaces it with the next request of its
 * kind, or the agent goes) is cancelled when it is deleted, so BlueZ is not
 * left waiting for its D-Bus timeout.
 */
class LuneOSBluetoothRequest : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool answered READ answered NOTIFY answeredChanged)

public:
    explicit LuneOSBluetoothRequest(const Request<> &request, QObject *parent = nullptr);
    explicit LuneOSBluetoothRequest(const Request<QString> &request, QObject *parent = nullptr);
    explicit LuneOSBluetoothRequest(const Request<quint32> &request, QObject *parent = nullptr);
    ~LuneOSBluetoothRequest() override;

    bool answered() const;

public Q_SLOTS:
    void accept(const QVariant &returnValue = QVariant());
    void reject();
    void cancel();

Q_SIGNALS:
    void answeredChanged();

private:
    bool markAnswered();

    bool mAnswered = false;

    enum RequestType {
        Void,
        String,
        UInt32
    } mRequestType;

    Request<> mRequestVoid;
    Request<QString> mRequestString;
    Request<quint32> mRequestUInt32;
};

#endif // LUNEOSBTREQUEST_H
