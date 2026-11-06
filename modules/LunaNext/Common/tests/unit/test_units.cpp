/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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

#include <gtest/gtest.h>

#include <cmath>

#include <QtGlobal>

#include "units.h"

using luna::Units;

namespace
{

/* Units reads the environment when one is made. The device's ui-scale file
 * (/var/luna/preferences/ui-scale) is not there on the build host, so the
 * environment is what these set. */
class UnitsTest : public ::testing::Test
{
protected:
    void TearDown() override
    {
        qunsetenv("LUNA_UI_SCALE");
        qunsetenv("GRID_UNIT_PX");
    }

    // Makes a Units with these, and returns its grid unit.
    float make(const char *uiScale, const char *gridUnit = "8")
    {
        qputenv("LUNA_UI_SCALE", uiScale);
        if (gridUnit)
            qputenv("GRID_UNIT_PX", gridUnit);
        else
            qunsetenv("GRID_UNIT_PX");
        Units units;
        return units.gridUnit();
    }
};

}

TEST_F(UnitsTest, aScaleThatIsNoNumberIsNoScale)
{
    // toFloat() reads these as numbers, and NaN passed both clamps.
    EXPECT_FLOAT_EQ(make("nan"), 8.0f);
    EXPECT_FLOAT_EQ(Units::uiScale(), 1.0f);
    make("inf");
    EXPECT_FLOAT_EQ(Units::uiScale(), 1.0f);
    make("-inf");
    EXPECT_FLOAT_EQ(Units::uiScale(), 1.0f);
}

TEST_F(UnitsTest, aScaleIsClamped)
{
    make("0.5");
    EXPECT_FLOAT_EQ(Units::uiScale(), 0.75f);
    make("3");
    EXPECT_FLOAT_EQ(Units::uiScale(), 1.5f);
    EXPECT_FLOAT_EQ(make("1.25"), 10.0f);
    EXPECT_FLOAT_EQ(Units::uiScale(), 1.25f);
}

TEST_F(UnitsTest, aGridUnitThatIsNoNumberIsNotTaken)
{
    // What the settings give when the environment says nothing.
    const float fromSettings = make("1", nullptr);
    const float taken = make("1", "nan");
    EXPECT_TRUE(std::isfinite(taken));
    EXPECT_FLOAT_EQ(taken, fromSettings);
}

TEST_F(UnitsTest, smallSizesKeepALineBelowAScaleOfOne)
{
    // A grid unit of 6 (8px at uiScale 0.75): 1dp and 2dp came out as 0.
    make("0.75");
    Units units;
    EXPECT_EQ(units.dp(1), 1);
    EXPECT_EQ(units.dp(2), 2);
    EXPECT_EQ(units.dp(4), 3);
}

TEST_F(UnitsTest, smallSizesAreWholeMultiplesAboveAScaleOfOne)
{
    make("1.5");
    Units units;
    EXPECT_EQ(units.dp(1), 1);
    EXPECT_EQ(units.dp(2), 2);
    EXPECT_EQ(units.dp(4), 6);
    make("1", "16");
    EXPECT_EQ(units.dp(1), 2);
    EXPECT_EQ(units.dp(4), 8);
}

TEST_F(UnitsTest, aScaleThatIsNoNumberIsNotWritten)
{
    Units units;
    EXPECT_FALSE(units.persistUiScale(NAN));
    EXPECT_FALSE(units.persistUiScale(INFINITY));
}
