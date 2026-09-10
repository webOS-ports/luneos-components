/*
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
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

#include <QtCore/qmath.h>
#include <QFile>
#include <QTextStream>
#include <Settings.h>
#include "units.h"

#define ENV_GRID_UNIT_PX "GRID_UNIT_PX"
#define DEFAULT_GRID_UNIT_PX 8

/*
 * How much larger or smaller than normal the interface should be drawn, as a
 * plain decimal on one line. Written by the shell when the Accessibility
 * panel changes the uiScale preference, and read here.
 *
 * A file and not an LS2 call: this runs in the constructor of a QML plugin
 * that every application loads before it draws anything, and a bus round
 * trip there would be a startup cost paid by every application on the
 * device for a value that changes about twice in the life of one.
 *
 * It also means the scale is fixed for the life of a process, which is why
 * the panel says a change shows up when an application is next started.
 */
#define UI_SCALE_FILE "/var/luna/preferences/ui-scale"
#define ENV_UI_SCALE "LUNA_UI_SCALE"

/* Below about three quarters the shell's own chrome stops fitting together,
 * and above about a half again the launcher runs out of room for a row of
 * icons. Values outside that are a mistake rather than a preference. */
#define MIN_UI_SCALE 0.75f
#define MAX_UI_SCALE 1.5f

namespace luna
{

float Units::mGridUnit = DEFAULT_GRID_UNIT_PX;
float Units::mUiScale = 1.0f;

static float getEnvFloat(const char* name, float defaultValue)
{
    QByteArray stringValue = qgetenv(name);
    bool ok;
    float value = stringValue.toFloat(&ok);
    return ok ? value : defaultValue;
}

static float readUiScale()
{
    float scale = 1.0f;

    QFile file(QStringLiteral(UI_SCALE_FILE));
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        bool ok = false;
        float value = QTextStream(&file).readLine().trimmed().toFloat(&ok);
        if (ok)
            scale = value;
    }

    // An environment variable still wins, the way it does for the grid unit,
    // so one application can be started larger without changing the device.
    scale = getEnvFloat(ENV_UI_SCALE, scale);

    if (scale < MIN_UI_SCALE)
        scale = MIN_UI_SCALE;
    if (scale > MAX_UI_SCALE)
        scale = MAX_UI_SCALE;

    return scale;
}

Units::Units()
{
    // This will eventually rewrite the static value, but within the same process we should always get the same value
    mUiScale = readUiScale();
    mGridUnit = getEnvFloat(ENV_GRID_UNIT_PX, Settings::LunaSettings()->gridUnit) * mUiScale;
}

float Units::uiScale()
{
    return mUiScale;
}

bool Units::persistUiScale(float scale)
{
    if (scale < MIN_UI_SCALE)
        scale = MIN_UI_SCALE;
    if (scale > MAX_UI_SCALE)
        scale = MAX_UI_SCALE;

    QFile file(QStringLiteral(UI_SCALE_FILE));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
        return false;

    QTextStream(&file) << scale << "\n";
    file.close();

    /* Not applied to this process: mGridUnit has already been read by
     * everything that laid itself out, and moving it under them would leave
     * half the screen at one size and half at another. Every application,
     * this one included, picks the new value up the next time it starts. */
    return true;
}

float Units::length(int lengthAt132DPI)
{
    return (lengthAt132DPI * Settings::LunaSettings()->layoutScale);
}

float Units::gridUnit()
{
    return mGridUnit;
}

void Units::setGridUnit(float gridUnit)
{
    mGridUnit = gridUnit;
    Q_EMIT gridUnitChanged();
}

float Units::dp(float value)
{
    return _dp(value);
}

float Units::_dp(float value)
{
    const float ratio = mGridUnit / DEFAULT_GRID_UNIT_PX;
    if (value <= 2.0)
        // for values under 2dp, return only multiples of the value
        return qRound(value * qFloor(ratio));
    return qRound(value * ratio);
}

float Units::gu(float value)
{
    return qRound(value * mGridUnit);
}

} // luna
