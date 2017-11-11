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

#ifndef LUNEOSBTAGENT_H
#define LUNEOSBTAGENT_H

#include <QSharedPointer>

#include <bluezqt/agent.h>
#include <bluezqt/device.h>
#include <bluezqt/request.h>
#include <bluezqt/manager.h>
#include <bluezqt/pendingcall.h>

#include "luneosbtrequest.h"

using namespace BluezQt;

class LuneOSBluetoothAgent : public Agent
{
    Q_OBJECT

    Q_PROPERTY(Capability capability READ capability WRITE setCapability NOTIFY capabilityChanged)
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)

public:
    explicit LuneOSBluetoothAgent();

    Capability capability() const;
    void setCapability(Capability iCapability);

    QString path() const;
    void setPath(const QString &iPath);

    virtual QDBusObjectPath objectPath() const;

    virtual void displayPinCode(DevicePtr device, const QString &pinCode);
    virtual void displayPasskey(DevicePtr device, const QString &passkey, const QString &entered);

    virtual void requestPinCode(DevicePtr device, const Request<QString> &request);
    virtual void requestPasskey(DevicePtr device, const Request<quint32> &request);

    virtual void requestConfirmation(DevicePtr device, const QString &passkey, const Request<> &request);
    virtual void requestAuthorization(DevicePtr device, const Request<> &request);

    virtual void authorizeService(DevicePtr device, const QString &uuid, const Request<> &request);


public Q_SLOTS:
    BluezQt::PendingCall *registerToManager(BluezQt::Manager *manager);

Q_SIGNALS:
    void capabilityChanged();
    void pathChanged();

    void displayPinCodeToUser(Device* device, const QString &pinCode);
    void displayPasskeyToUser(Device* device, const QString &passkey, const QString &entered);

    void requestPinCodeFromUser(Device* device, LuneOSBluetoothRequest* request);
    void requestPasskeyFromUser(Device* device, LuneOSBluetoothRequest* request);

    void requestConfirmationFromUser(Device* device, const QString &passkey, LuneOSBluetoothRequest* request);
    void requestAuthorizationFromUser(Device* device, LuneOSBluetoothRequest* request);

    void authorizeServiceFromUser(Device* device, const QString &uuid, LuneOSBluetoothRequest* request);

    void cancel();
    void release();

private:
    Capability mCapability;
    QString mPath;

    QSharedPointer<LuneOSBluetoothRequest> mPinCodeRequestPtr;
    QSharedPointer<LuneOSBluetoothRequest> mPasskeyRequestPtr;
    QSharedPointer<LuneOSBluetoothRequest> mConfirmationRequestPtr;
    QSharedPointer<LuneOSBluetoothRequest> mAuthorizationRequestPtr;
    QSharedPointer<LuneOSBluetoothRequest> mServiceRequestPtr;
};

#endif // LUNEOSBTAGENT_H
