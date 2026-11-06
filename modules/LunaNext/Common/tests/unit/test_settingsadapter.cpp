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

#include <QRect>

#include <Settings.h>

#include "settingsadapter.h"

using luna::SettingsAdapter;

namespace
{

QVariantList cutouts(const char *raw)
{
    Settings::LunaSettings()->displayCutouts = raw;
    return SettingsAdapter().displayCutouts();
}

QVariantList radii(const char *raw)
{
    Settings::LunaSettings()->displayCornerRadii = raw;
    return SettingsAdapter().displayCornerRadii();
}

}

TEST(SettingsAdapter, cutoutsAreRects)
{
    const QVariantList two = cutouts("0 0 40 96;505 21 70 71");
    ASSERT_EQ(two.count(), 2);
    EXPECT_EQ(two.at(0).toRect(), QRect(0, 0, 40, 96));
    EXPECT_EQ(two.at(1).toRect(), QRect(505, 21, 70, 71));
    EXPECT_TRUE(cutouts("").isEmpty());
}

TEST(SettingsAdapter, aCutoutWithAFieldThatIsNoNumberIsDropped)
{
    // Leaving out only the "x" gave four numbers, and the rect 1,2 3x4.
    const QVariantList kept = cutouts("1 2 x 3 4;505 21 70 71");
    ASSERT_EQ(kept.count(), 1);
    EXPECT_EQ(kept.at(0).toRect(), QRect(505, 21, 70, 71));
    EXPECT_TRUE(cutouts("1 2 3 4x").isEmpty());
}

TEST(SettingsAdapter, aCutoutWithoutFourFieldsOrAreaIsDropped)
{
    EXPECT_TRUE(cutouts("1 2 3").isEmpty());
    EXPECT_TRUE(cutouts("1 2 3 4 5").isEmpty());
    EXPECT_TRUE(cutouts("1 2 0 4").isEmpty());
}

TEST(SettingsAdapter, cornerRadiiAreOneOrFour)
{
    EXPECT_EQ(radii("75"), QVariantList() << 75 << 75 << 75 << 75);
    EXPECT_EQ(radii("10;20;30;40"), QVariantList() << 10 << 20 << 30 << 40);
    EXPECT_EQ(radii("10;-5;30;40"), QVariantList() << 10 << 0 << 30 << 40);
    EXPECT_TRUE(radii("10;20").isEmpty());
    EXPECT_TRUE(radii("").isEmpty());
}

TEST(SettingsAdapter, cornerRadiiWithOneThatIsNoNumberAreDropped)
{
    // "x;75" was one value, applied to all four corners; the other, four
    // radii each a corner off.
    EXPECT_TRUE(radii("x;75").isEmpty());
    EXPECT_TRUE(radii("10;x;20;30;40").isEmpty());
}
