/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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

#include <QtQml>

#include "plugin.h"
#include "luneosbtagent.h"
#include "luneosbtrequest.h"

Plugin::Plugin(QObject *parent) :
    QQmlExtensionPlugin(parent)
{
}

void Plugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("LuneOS.Bluetooth"));
    qmlRegisterType<LuneOSBluetoothAgent>(uri, 0, 2, "LuneOSBluetoothAgent");
    qmlRegisterUncreatableType<LuneOSBluetoothRequest>(uri, 0, 2, "LuneOSBluetoothRequest", "LuneOSBluetoothRequest cannot be created in QML.");
}

void Plugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_UNUSED(engine);
    Q_UNUSED(uri);
}