/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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

#include "luneosbutton.h"
#include "luneosradiobutton.h"
#include "luneosswitch.h"
#include "luneosswipedelegate.h"

QtQuickControls2LuneOSStylePlugin::QtQuickControls2LuneOSStylePlugin(QObject *parent) :
    QQmlExtensionPlugin(parent)
{
}

void QtQuickControls2LuneOSStylePlugin::registerTypes(const char *uri)
{
    qmlRegisterUncreatableType<LuneOSSwitch>(uri, 2, 0, "LuneOSSwitch", tr("LuneOSSwitch is an attached property"));
    qmlRegisterUncreatableType<LuneOSRadioButton>(uri, 2, 0, "LuneOSRadioButton", tr("LuneOSRadioButton is an attached property"));
    qmlRegisterUncreatableType<LuneOSButton>(uri, 2, 0, "LuneOSButton", tr("LuneOSButton is an attached property"));
    qmlRegisterUncreatableType<LuneOSSwipeDelegate>(uri, 2, 0, "LuneOSSwipeDelegate", tr("LuneOSSwipeDelegate is an attached property"));
}

void QtQuickControls2LuneOSStylePlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_UNUSED(engine);
    Q_UNUSED(uri);
}
