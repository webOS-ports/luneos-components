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

#ifndef UNITS_H_
#define UNITS_H_

#include <QObject>

namespace luna
{

class Units : public QObject
{
    Q_OBJECT
    Q_PROPERTY(float gridUnit READ gridUnit WRITE setGridUnit NOTIFY gridUnitChanged)
    /* What the interface is being scaled by, for a page that wants to show it.
     * Read only: it is fixed for the life of a process - see units.cpp. */
    Q_PROPERTY(float uiScale READ uiScale CONSTANT)

public:
    explicit Units();

    Q_INVOKABLE float length(int lengthAt132DPI);

    Q_INVOKABLE float dp(float value);
    Q_INVOKABLE float gu(float value);
    QString resolveResource(const QUrl& url);

    float gridUnit();
    void setGridUnit(float gridUnit);

    static float uiScale();

    /* Writes the scale the whole device is drawn at. Narrow on purpose: this
     * is not a general file writer handed to QML, it takes one number and
     * writes one known file. Only the shell has any business calling it. */
    Q_INVOKABLE bool persistUiScale(float scale);

Q_SIGNALS:
    void gridUnitChanged();

private:
    static float mGridUnit;
    static float mUiScale;

    static float _dp(float value);
    friend class FontUtils;
};

}

#endif
