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

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QTemporaryDir>
#include <QUrl>

#include <thread>
#include <vector>

#include "artworkcache.h"

/* A picture 40 wide and 20 high: green on the left half, blue on the right. */
static const char *twoHalves =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"20\" viewBox=\"0 0 40 20\">"
    "<rect width=\"20\" height=\"20\" fill=\"#00ff00\"/><rect x=\"20\" width=\"20\" height=\"20\" fill=\"#0000ff\"/></svg>";
static const char *allRed =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"20\"><rect width=\"40\" height=\"20\" fill=\"#ff0000\"/></svg>";

static QString writeSvg(const QString &dir, const QString &file, const char *svg)
{
    QDir().mkpath(dir);
    const QString path = dir + QLatin1Char('/') + file;
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly))
        return QString();
    f.write(svg);
    return path;
}

class ArtworkCacheTest : public ::testing::Test
{
protected:
    void SetUp() override
    {
        ASSERT_TRUE(dir.isValid());
        images = dir.path() + QStringLiteral("/app/qml/images");
        cacheDir = dir.path() + QStringLiteral("/cache/artwork");
        halves = writeSvg(images, QStringLiteral("halves.svg"), twoHalves);
        ASSERT_FALSE(halves.isEmpty());
    }

    QTemporaryDir dir;
    QString images, cacheDir, halves;
};

TEST_F(ArtworkCacheTest, DrawsAtTheSizeAskedForAndKeepsIt)
{
    ArtworkCache cache(cacheDir);
    QSize original;
    const QImage image = cache.image(halves, QSize(80, 40), &original);
    ASSERT_FALSE(image.isNull());
    EXPECT_EQ(image.size(), QSize(80, 40));
    EXPECT_EQ(original, QSize(80, 40));
    EXPECT_EQ(qGreen(image.pixel(10, 20)), 255);
    EXPECT_EQ(qBlue(image.pixel(70, 20)), 255);

    const QString kept = cache.cachePath(halves, QSize(80, 40));
    ASSERT_TRUE(QFileInfo::exists(kept));
    EXPECT_TRUE(kept.startsWith(cacheDir + QLatin1Char('/')));
    EXPECT_EQ(QImage(kept).size(), QSize(80, 40));
}

TEST_F(ArtworkCacheTest, LoadsTheKeptPictureNextTime)
{
    ArtworkCache cache(cacheDir);
    ASSERT_FALSE(cache.image(halves, QSize(80, 40)).isNull());
    // Replace the kept file with a red one: if it is read, the red comes back.
    QImage red(80, 40, QImage::Format_ARGB32);
    red.fill(Qt::red);
    ASSERT_TRUE(red.save(cache.cachePath(halves, QSize(80, 40)), "PNG"));
    const QImage again = cache.image(halves, QSize(80, 40));
    EXPECT_EQ(qRed(again.pixel(70, 20)), 255);
    EXPECT_EQ(qBlue(again.pixel(70, 20)), 0);
}

TEST_F(ArtworkCacheTest, KeepsItsProportionsWhenOnlyOneSideIsGiven)
{
    ArtworkCache cache(cacheDir);
    QSize original;
    EXPECT_EQ(cache.image(halves, QSize(60, 0), &original).size(), QSize(60, 30));
    EXPECT_EQ(original, QSize(60, 30));
    EXPECT_EQ(cache.image(halves, QSize(0, 10)).size(), QSize(20, 10));
    // Neither: the picture's own size.
    EXPECT_EQ(cache.image(halves, QSize()).size(), QSize(40, 20));
}

TEST_F(ArtworkCacheTest, TakesOnlyAbsoluteSvgFiles)
{
    ArtworkCache cache(cacheDir);
    EXPECT_TRUE(cache.image(QStringLiteral("app/qml/images/halves.svg"), QSize(10, 10)).isNull());
    EXPECT_TRUE(cache.image(images + QStringLiteral("/missing.svg"), QSize(10, 10)).isNull());
    EXPECT_TRUE(cache.image(images, QSize(10, 10)).isNull());
    const QString png = images + QStringLiteral("/halves.png");
    QImage notSvg(4, 4, QImage::Format_ARGB32);
    notSvg.fill(Qt::white);
    ASSERT_TRUE(notSvg.save(png, "PNG"));
    EXPECT_TRUE(cache.image(png, QSize(10, 10)).isNull());
    const QString broken = writeSvg(images, QStringLiteral("broken.svg"), "<svg");
    EXPECT_TRUE(cache.image(broken, QSize(10, 10)).isNull());
}

TEST_F(ArtworkCacheTest, RefusesSizesNoArtworkNeeds)
{
    ArtworkCache cache(cacheDir);
    EXPECT_TRUE(cache.image(halves, QSize(5000, 10)).isNull());
    EXPECT_TRUE(cache.image(halves, QSize(10, 5000)).isNull());
}

TEST_F(ArtworkCacheTest, AChangedPictureReplacesOnlyItsOwnOldFiles)
{
    const QString pressed = writeSvg(images, QStringLiteral("halves-pressed.svg"), twoHalves);
    ArtworkCache cache(cacheDir);
    ASSERT_FALSE(cache.image(halves, QSize(40, 20)).isNull());
    ASSERT_FALSE(cache.image(pressed, QSize(40, 20)).isNull());
    const QString oldPath = cache.cachePath(halves, QSize(40, 20));
    const QString pressedPath = cache.cachePath(pressed, QSize(40, 20));

    writeSvg(images, QStringLiteral("halves.svg"), allRed);
    const QImage changed = cache.image(halves, QSize(40, 20));
    EXPECT_EQ(qRed(changed.pixel(30, 10)), 255);
    const QString newPath = cache.cachePath(halves, QSize(40, 20));
    EXPECT_NE(newPath, oldPath);
    EXPECT_TRUE(QFileInfo::exists(newPath));
    EXPECT_FALSE(QFileInfo::exists(oldPath));
    // "halves-pressed" starts with "halves-" but is another picture: kept.
    EXPECT_TRUE(QFileInfo::exists(pressedPath));
}

TEST_F(ArtworkCacheTest, EachAppsArtworkHasItsOwnFolder)
{
    // Another app with a picture of the same name, drawn differently.
    const QString other = writeSvg(dir.path() + QStringLiteral("/other/qml/images"), QStringLiteral("halves.svg"), allRed);
    ArtworkCache cache(cacheDir);
    ASSERT_FALSE(cache.image(halves, QSize(40, 20)).isNull());
    const QImage theirs = cache.image(other, QSize(40, 20));
    EXPECT_EQ(qRed(theirs.pixel(30, 10)), 255);
    EXPECT_NE(QFileInfo(cache.cachePath(halves, QSize(40, 20))).path(), QFileInfo(cache.cachePath(other, QSize(40, 20))).path());
    // Neither app's picture took the other's place.
    EXPECT_TRUE(QFileInfo::exists(cache.cachePath(halves, QSize(40, 20))));
    EXPECT_EQ(qBlue(cache.image(halves, QSize(40, 20)).pixel(30, 10)), 255);
}

TEST_F(ArtworkCacheTest, NamesThatAreNotPlainAreMadePlain)
{
    const QString odd = writeSvg(images, QStringLiteral("weïrd name;1.svg"), twoHalves);
    ArtworkCache cache(cacheDir);
    ASSERT_FALSE(cache.image(odd, QSize(40, 20)).isNull());
    const QString kept = QFileInfo(cache.cachePath(odd, QSize(40, 20))).fileName();
    EXPECT_TRUE(QFileInfo::exists(cache.cachePath(odd, QSize(40, 20))));
    EXPECT_TRUE(kept.startsWith(QStringLiteral("we_rd_name_1-40x20-"))) << qPrintable(kept);
}

TEST_F(ArtworkCacheTest, ReadsThePathOutOfAnId)
{
    // ArtworkImage.qml sends the path encodeURIComponent()ed; a file: URL works too.
    EXPECT_EQ(ArtworkCache::pathFromId(QStringLiteral("%2Fusr%2Fpalm%2Fa%20b.svg")), QStringLiteral("/usr/palm/a b.svg"));
    EXPECT_EQ(ArtworkCache::pathFromId(QStringLiteral("/usr/palm/a.svg")), QStringLiteral("/usr/palm/a.svg"));
    EXPECT_EQ(ArtworkCache::pathFromId(QStringLiteral("file%3A%2F%2F%2Fusr%2Fpalm%2Fa.svg")), QStringLiteral("/usr/palm/a.svg"));
    EXPECT_EQ(ArtworkCache::pathFromId(QStringLiteral("file:///usr/palm/a%20b.svg")), QStringLiteral("/usr/palm/a b.svg"));
}

TEST_F(ArtworkCacheTest, DrawsEvenWhereNothingCanBeKept)
{
    // The cache directory's place is taken by a file, so nothing can be saved.
    QFile blocker(dir.path() + QStringLiteral("/blocked"));
    ASSERT_TRUE(blocker.open(QIODevice::WriteOnly));
    blocker.close();
    ArtworkCache cache(dir.path() + QStringLiteral("/blocked/artwork"));
    const QImage image = cache.image(halves, QSize(40, 20));
    ASSERT_FALSE(image.isNull());
    EXPECT_EQ(qGreen(image.pixel(5, 10)), 255);
}

TEST_F(ArtworkCacheTest, ManyAtOnceAllGetThePicture)
{
    // The image provider runs requests on a thread pool: the same picture asked
    // for at once, with nothing kept yet, must come out whole every time.
    ArtworkCache cache(cacheDir);
    std::vector<QImage> pictures(8);
    std::vector<std::thread> threads;
    for (size_t i = 0; i < pictures.size(); ++i)
        threads.emplace_back([&cache, &pictures, i, this] { pictures[i] = cache.image(halves, QSize(80, 40)); });
    for (std::thread &t : threads)
        t.join();
    for (const QImage &image : pictures) {
        ASSERT_EQ(image.size(), QSize(80, 40));
        EXPECT_EQ(qGreen(image.pixel(10, 20)), 255);
        EXPECT_EQ(qBlue(image.pixel(70, 20)), 255);
    }
    EXPECT_EQ(QImage(cache.cachePath(halves, QSize(80, 40))).size(), QSize(80, 40));
}
