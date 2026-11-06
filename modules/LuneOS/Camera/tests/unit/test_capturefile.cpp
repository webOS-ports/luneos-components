/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <gtest/gtest.h>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>

#include "capturefile.h"

static QByteArray contents(const QString &path)
{
    QFile file(path);
    return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray();
}

TEST(CaptureFile, WritesTheNameAskedFor)
{
    QTemporaryDir dir;
    const QString path = dir.filePath("2026-11-06-07-30-00.jpg");
    EXPECT_EQ(writeNewCaptureFile(path, "first"), path);
    EXPECT_EQ(contents(path), QByteArray("first"));
}

TEST(CaptureFile, ASecondShotInTheSameSecondKeepsTheFirst)
{
    // The app names pictures to the second; the second shot replaced the first.
    QTemporaryDir dir;
    const QString path = dir.filePath("2026-11-06-07-30-00.jpg");
    ASSERT_EQ(writeNewCaptureFile(path, "first"), path);
    const QString second = writeNewCaptureFile(path, "second");
    EXPECT_EQ(second, dir.filePath("2026-11-06-07-30-00-1.jpg"));
    EXPECT_EQ(writeNewCaptureFile(path, "third"), dir.filePath("2026-11-06-07-30-00-2.jpg"));
    EXPECT_EQ(contents(path), QByteArray("first"));
    EXPECT_EQ(contents(second), QByteArray("second"));
}

TEST(CaptureFile, DoesNotWriteThroughASymlink)
{
    QTemporaryDir dir;
    const QString target = dir.filePath("elsewhere");
    ASSERT_TRUE(QFile::link(target, dir.filePath("shot.jpg")));
    const QString saved = writeNewCaptureFile(dir.filePath("shot.jpg"), "picture");
    EXPECT_EQ(saved, dir.filePath("shot-1.jpg"));
    EXPECT_FALSE(QFileInfo::exists(target));
    EXPECT_EQ(contents(saved), QByteArray("picture"));
}

TEST(CaptureFile, AFolderThatCannotBeWrittenGivesNothing)
{
    QTemporaryDir dir;
    EXPECT_TRUE(writeNewCaptureFile(dir.filePath("missing/shot.jpg"), "picture").isEmpty());
    EXPECT_TRUE(writeNewCaptureFile(QString(), "picture").isEmpty());
}
