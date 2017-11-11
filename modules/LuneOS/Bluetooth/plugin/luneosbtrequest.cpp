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
#include <QVariant>

#include <bluezqt/agent.h>
#include <bluezqt/device.h>
#include <bluezqt/request.h>

#include "luneosbtrequest.h"

LuneOSBluetoothRequest::LuneOSBluetoothRequest(const Request<> &request, QObject *parent): QObject(parent),
    mRequestType(LuneOSBluetoothRequest::Void),
    mRequestVoid(request)
{
}

LuneOSBluetoothRequest::LuneOSBluetoothRequest(const Request<quint32> &request, QObject *parent): QObject(parent),
    mRequestType(LuneOSBluetoothRequest::UInt32),
    mRequestUInt32(request)
{
}

LuneOSBluetoothRequest::LuneOSBluetoothRequest(const Request<QString> &request, QObject *parent): QObject(parent),
    mRequestType(LuneOSBluetoothRequest::String),
    mRequestString(request)
{
}

void LuneOSBluetoothRequest::accept(QVariant returnValue) const
{
    if(mRequestType == LuneOSBluetoothRequest::Void) {
        mRequestVoid.accept();
    }
    else if(mRequestType == LuneOSBluetoothRequest::UInt32) {
        mRequestUInt32.accept(returnValue.toUInt());
    }
    else if(mRequestType == LuneOSBluetoothRequest::String) {
        mRequestString.accept(returnValue.toString());
    }
}

void LuneOSBluetoothRequest::reject() const
{
    if(mRequestType == LuneOSBluetoothRequest::Void) {
        mRequestVoid.reject();
    }
    else if(mRequestType == LuneOSBluetoothRequest::UInt32) {
        mRequestUInt32.reject();
    }
    else if(mRequestType == LuneOSBluetoothRequest::String) {
        mRequestString.reject();
    }
}
void LuneOSBluetoothRequest::cancel() const
{
    if(mRequestType == LuneOSBluetoothRequest::Void) {
        mRequestVoid.cancel();
    }
    else if(mRequestType == LuneOSBluetoothRequest::UInt32) {
        mRequestUInt32.cancel();
    }
    else if(mRequestType == LuneOSBluetoothRequest::String) {
        mRequestString.cancel();
    }
}

