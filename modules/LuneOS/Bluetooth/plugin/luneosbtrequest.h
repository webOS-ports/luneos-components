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

class LuneOSBluetoothRequest : public QObject
{
    Q_OBJECT

public:
    explicit LuneOSBluetoothRequest(const Request<> &request, QObject *parent = nullptr);
    explicit LuneOSBluetoothRequest(const Request<QString> &request, QObject *parent = nullptr);
    explicit LuneOSBluetoothRequest(const Request<quint32> &request, QObject *parent = nullptr);

public Q_SLOTS:
    void accept(QVariant returnValue = QVariant()) const;
    void reject() const;
    void cancel() const;

private:
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
