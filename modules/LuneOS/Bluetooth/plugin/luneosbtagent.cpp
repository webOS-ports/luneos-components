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

#include <QDebug>
#include <QDBusObjectPath>

#include <bluezqt/agent.h>
#include <bluezqt/device.h>
#include <bluezqt/request.h>
#include <bluezqt/manager.h>
#include <bluezqt/pendingcall.h>

#include "luneosbtagent.h"
#include "luneosbtrequest.h"

LuneOSBluetoothAgent::LuneOSBluetoothAgent():
    mCapability(NoInputNoOutput),
    mPath("/")
{
}

void LuneOSBluetoothAgent::requestPinCode(DevicePtr device, const Request<QString> &request)
{
    mPinCodeRequestPtr.reset(new LuneOSBluetoothRequest(request));
    requestPinCodeFromUser(device, mPinCodeRequestPtr.data());
}

void LuneOSBluetoothAgent::requestPasskey(DevicePtr device, const Request<quint32> &request)
{
    mPasskeyRequestPtr.reset(new LuneOSBluetoothRequest(request));
    requestPasskeyFromUser(device, mPasskeyRequestPtr.data()); // that'll leak, isn't it
}

void LuneOSBluetoothAgent::requestConfirmation(DevicePtr device, const QString &passkey, const Request<> &request)
{
    mConfirmationRequestPtr.reset(new LuneOSBluetoothRequest(request));
    requestConfirmationFromUser(device, passkey, mConfirmationRequestPtr.data()); // that'll leak, isn't it
}
void LuneOSBluetoothAgent::requestAuthorization(DevicePtr device, const Request<> &request)
{
    mAuthorizationRequestPtr.reset(new LuneOSBluetoothRequest(request));
    requestAuthorizationFromUser(device, mAuthorizationRequestPtr.data()); // that'll leak, isn't it
}

void LuneOSBluetoothAgent::authorizeService(DevicePtr device, const QString &uuid, const Request<> &request)
{
    mServiceRequestPtr.reset(new LuneOSBluetoothRequest(request));
    authorizeServiceFromUser(device, uuid, mServiceRequestPtr.data()); // that'll leak, isn't it
}

QDBusObjectPath LuneOSBluetoothAgent::objectPath() const
{
    return QDBusObjectPath(mPath);
}

PendingCall *LuneOSBluetoothAgent::registerToManager(Manager *manager)
{
    return manager->registerAgent(this);
}

void LuneOSBluetoothAgent::setCapability(Capability iCapability)
{
    if(mCapability != iCapability) {
        mCapability = iCapability;
        capabilityChanged();
    }
}

LuneOSBluetoothAgent::Capability LuneOSBluetoothAgent::capability() const
{
    return mCapability;
}

void LuneOSBluetoothAgent::setPath(const QString &iPath)
{
    if(mPath != iPath) {
        mPath = iPath;
        pathChanged();
    }
}

QString LuneOSBluetoothAgent::path() const
{
    return mPath;
}
