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

#include <QImage>
#include <QTemporaryDir>
#include <QUrl>

#include "reticleitem.h"

using luna::ReticleItem;

TEST(ReticleItem, imagePathIsAPropertyQmlCanSet)
{
    // Without a READ accessor moc made imagePath an invalid property, which
    // a Reticle { imagePath: ... } in QML could not set.
    ReticleItem item;
    const QUrl path = QUrl::fromLocalFile("/usr/share/reticle.png");
    ASSERT_TRUE(item.setProperty("imagePath", path));
    EXPECT_EQ(item.property("imagePath").toUrl(), path);
}

TEST(ReticleItem, takesItsSizeFromTheImage)
{
    QTemporaryDir dir;
    ASSERT_TRUE(dir.isValid());
    QImage image(24, 16, QImage::Format_ARGB32);
    image.fill(Qt::white);
    ASSERT_TRUE(image.save(dir.filePath("reticle.png")));

    ReticleItem item;
    ASSERT_TRUE(item.setProperty("imagePath", QUrl::fromLocalFile(dir.filePath("reticle.png"))));
    item.componentComplete();
    EXPECT_EQ(item.width(), 24);
    EXPECT_EQ(item.height(), 16);
}
