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

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QTemporaryDir>

#include "screenshooter.h"

using luna::ScreenShooter;

namespace
{

QImage redSquare()
{
    QImage image(8, 8, QImage::Format_ARGB32);
    image.fill(Qt::red);
    return image;
}

QDateTime fixedTime()
{
    return QDateTime(QDate(2026, 10, 29), QTime(15, 4, 5));
}

QByteArray readAll(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return QByteArray();
    return f.readAll();
}

class ScreenShooterSave : public ::testing::Test
{
protected:
    void SetUp() override
    {
        ASSERT_TRUE(tmp.isValid());
        dir = tmp.path() + QStringLiteral("/screencaptures");
        ASSERT_TRUE(QDir().mkpath(dir));
    }

    QTemporaryDir tmp;
    QString dir;
};

} // namespace

TEST(ScreenShooterName, AcceptsPlainNames)
{
    EXPECT_TRUE(ScreenShooter::isPlainFileName(QStringLiteral("shot.png")));
    EXPECT_TRUE(ScreenShooter::isPlainFileName(QStringLiteral("my shot 1.jpg")));
    EXPECT_TRUE(ScreenShooter::isPlainFileName(QStringLiteral("a..b.png")));
    EXPECT_TRUE(ScreenShooter::isPlainFileName(QString::fromUtf8("sch\xc3\xb6n.png")));
    EXPECT_TRUE(ScreenShooter::isPlainFileName(QString(255, QLatin1Char('a'))));
}

TEST(ScreenShooterName, RejectsPathsAndSpecialNames)
{
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QString()));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QStringLiteral(".")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QStringLiteral("..")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QStringLiteral(".hidden.png")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QStringLiteral("../shot.png")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QStringLiteral("sub/shot.png")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QStringLiteral("/etc/passwd")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QStringLiteral("a\\b.png")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QStringLiteral("a\nb.png")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QStringLiteral("a\x7f" "b.png")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QString(QChar(0)) + QStringLiteral("x.png")));
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QString(256, QLatin1Char('a'))));
    /* 128 two-byte characters are 256 bytes, over NAME_MAX. */
    EXPECT_FALSE(ScreenShooter::isPlainFileName(QString(128, QChar(0x00f6))));
}

TEST(ScreenShooterDirectory, IsTheScreencapturesFolder)
{
    EXPECT_STREQ(ScreenShooter::kDirectory, "/media/internal/screencaptures");
}

TEST_F(ScreenShooterSave, WritesAPlainName)
{
    const QString path = ScreenShooter::save(redSquare(), dir, QStringLiteral("shot.png"), fixedTime());
    EXPECT_EQ(path, dir + QStringLiteral("/shot.png"));
    QImage back(path);
    ASSERT_FALSE(back.isNull());
    EXPECT_EQ(back.pixelColor(0, 0), QColor(Qt::red));
}

TEST_F(ScreenShooterSave, EmptyNameIsTimestamped)
{
    const QString path = ScreenShooter::save(redSquare(), dir, QString(), fixedTime());
    EXPECT_EQ(path, dir + QStringLiteral("/20261029150405.png"));
    EXPECT_TRUE(QFileInfo::exists(path));
}

TEST_F(ScreenShooterSave, TimestampCollisionGetsASuffix)
{
    const QString first = ScreenShooter::save(redSquare(), dir, QString(), fixedTime());
    const QString second = ScreenShooter::save(redSquare(), dir, QString(), fixedTime());
    EXPECT_EQ(first, dir + QStringLiteral("/20261029150405.png"));
    EXPECT_EQ(second, dir + QStringLiteral("/20261029150405-1.png"));
}

TEST_F(ScreenShooterSave, RefusesTraversal)
{
    EXPECT_TRUE(ScreenShooter::save(redSquare(), dir, QStringLiteral("../escape.png"), fixedTime()).isEmpty());
    EXPECT_FALSE(QFileInfo::exists(tmp.path() + QStringLiteral("/escape.png")));
}

TEST_F(ScreenShooterSave, RefusesAbsolutePath)
{
    const QString target = tmp.path() + QStringLiteral("/abs.png");
    EXPECT_TRUE(ScreenShooter::save(redSquare(), dir, target, fixedTime()).isEmpty());
    EXPECT_FALSE(QFileInfo::exists(target));
}

TEST_F(ScreenShooterSave, DoesNotOverwriteAnExistingFile)
{
    QFile f(dir + QStringLiteral("/keep.png"));
    ASSERT_TRUE(f.open(QIODevice::WriteOnly));
    f.write("precious");
    f.close();
    EXPECT_TRUE(ScreenShooter::save(redSquare(), dir, QStringLiteral("keep.png"), fixedTime()).isEmpty());
    EXPECT_EQ(readAll(dir + QStringLiteral("/keep.png")), QByteArray("precious"));
}

TEST_F(ScreenShooterSave, DoesNotWriteThroughASymlink)
{
    const QString victim = tmp.path() + QStringLiteral("/victim");
    QFile v(victim);
    ASSERT_TRUE(v.open(QIODevice::WriteOnly));
    v.write("root-owned");
    v.close();
    ASSERT_TRUE(QFile::link(victim, dir + QStringLiteral("/link.png")));
    EXPECT_TRUE(ScreenShooter::save(redSquare(), dir, QStringLiteral("link.png"), fixedTime()).isEmpty());
    EXPECT_EQ(readAll(victim), QByteArray("root-owned"));
}

TEST_F(ScreenShooterSave, RefusesASymlinkedDirectory)
{
    const QString elsewhere = tmp.path() + QStringLiteral("/elsewhere");
    ASSERT_TRUE(QDir().mkpath(elsewhere));
    const QString linked = tmp.path() + QStringLiteral("/linkdir");
    ASSERT_TRUE(QFile::link(elsewhere, linked));
    EXPECT_TRUE(ScreenShooter::save(redSquare(), linked, QStringLiteral("shot.png"), fixedTime()).isEmpty());
    EXPECT_FALSE(QFileInfo::exists(elsewhere + QStringLiteral("/shot.png")));
}

TEST_F(ScreenShooterSave, CreatesAMissingDirectory)
{
    const QString fresh = tmp.path() + QStringLiteral("/fresh");
    const QString path = ScreenShooter::save(redSquare(), fresh, QStringLiteral("shot.png"), fixedTime());
    EXPECT_EQ(path, fresh + QStringLiteral("/shot.png"));
    EXPECT_TRUE(QFileInfo::exists(path));
}

TEST_F(ScreenShooterSave, UnknownFormatLeavesNothingBehind)
{
    EXPECT_TRUE(ScreenShooter::save(redSquare(), dir, QStringLiteral("shot.notaformat"), fixedTime()).isEmpty());
    EXPECT_FALSE(QFileInfo::exists(dir + QStringLiteral("/shot.notaformat")));
    EXPECT_TRUE(ScreenShooter::save(redSquare(), dir, QStringLiteral("noext"), fixedTime()).isEmpty());
    EXPECT_FALSE(QFileInfo::exists(dir + QStringLiteral("/noext")));
}
