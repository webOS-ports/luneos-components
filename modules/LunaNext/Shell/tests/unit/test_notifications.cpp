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

#include <cstring>
#include <new>

#include <QFile>
#include <QPointer>
#include <QSignalSpy>
#include <QTemporaryDir>

#include "notifications/categorydefinitionstore.h"
#include "notifications/notification.h"
#include "notifications/notificationmanager.h"
#include "notifications/qobjectlistmodel.h"

namespace
{

void writeFile(const QString &path, const QByteArray &content)
{
    QFile file(path);
    ASSERT_TRUE(file.open(QIODevice::WriteOnly));
    file.write(content);
}

}

TEST(Notification, defaultConstructedHasDefinedValues)
{
    // Built over memory that is not zero, so a field left out shows.
    alignas(Notification) unsigned char memory[sizeof(Notification)];
    std::memset(memory, 0xa5, sizeof(memory));
    Notification *notification = new (memory) Notification;
    EXPECT_EQ(notification->duration(), 0);
    EXPECT_FALSE(notification->doNotSuppress());
    EXPECT_EQ(notification->priority(), 0);
    EXPECT_EQ(notification->replacesId(), 0u);
    EXPECT_EQ(notification->expireTimeout(), -1);
    notification->~Notification();
}

TEST(QObjectListModel, setDataStoresTheObjectGiven)
{
    QObjectListModel model;
    QObject first, second;
    model.addItem(&first);
    const QModelIndex index = model.index(0, 0);
    const int role = Qt::UserRole + 1;

    EXPECT_TRUE(model.setData(index, QVariant::fromValue(&second), role));
    EXPECT_EQ(model.get(0), &second);
    EXPECT_EQ(model.data(index, role).value<QObject*>(), &second);

    // A number is no object: it used to be stored as a pointer.
    EXPECT_FALSE(model.setData(index, QVariant(1234), role));
    EXPECT_EQ(model.get(0), &second);
}

TEST(QObjectListModel, aReplacedItemIsWatchedInstead)
{
    QObjectListModel model;
    QObject kept;
    QObject *replaced = new QObject;
    QObject *placed = new QObject;
    model.addItem(replaced);
    ASSERT_TRUE(model.setData(model.index(0, 0), QVariant::fromValue(placed), Qt::UserRole + 1));

    // The item that is no longer in the list takes nothing with it.
    model.addItem(&kept);
    delete replaced;
    EXPECT_EQ(model.itemCount(), 2);

    // The one put in its place leaves the list when it goes.
    delete placed;
    ASSERT_EQ(model.itemCount(), 1);
    EXPECT_EQ(model.get(0), &kept);
}

TEST(QObjectListModel, removeItemOutOfRangeDoesNothing)
{
    QObjectListModel model;
    QObject item;
    model.addItem(&item);
    model.removeItem(5);
    model.removeItem(-1);
    EXPECT_EQ(model.itemCount(), 1);
}

TEST(CategoryDefinitionStore, aRemovedDefinitionIsUninstalled)
{
    QTemporaryDir dir;
    ASSERT_TRUE(dir.isValid());
    writeFile(dir.filePath("first.conf"), "[General]\nkey=1\n");
    writeFile(dir.filePath("second.conf"), "[General]\nkey=2\n");
    writeFile(dir.filePath("third.conf"), "[General]\nkey=3\n");

    CategoryDefinitionStore store(dir.path());
    QSignalSpy uninstalled(&store, &CategoryDefinitionStore::categoryDefinitionUninstalled);
    EXPECT_TRUE(store.categoryDefinitionExists("second"));

    ASSERT_TRUE(QFile::remove(dir.filePath("second.conf")));
    // What the directory watcher calls.
    ASSERT_TRUE(QMetaObject::invokeMethod(&store, "updateCategoryDefinitionFileList"));

    ASSERT_EQ(uninstalled.count(), 1);
    EXPECT_EQ(uninstalled.at(0).at(0).toString(), QString("second"));
    EXPECT_EQ(store.value("first", "key"), QString("1"));
    EXPECT_EQ(store.value("third", "key"), QString("3"));
}

TEST(NotificationManager, destroyedWithNotificationsUsesNoFreedDatabase)
{
    // The manager is made once for the process; this destroys it, and is the
    // only test that uses it. Its database is in /var/luna/data, which a
    // test on the build host cannot write: it stays closed, which is enough,
    // as the old destructor asked the deleted database whether it was open.
    QPointer<NotificationManager> manager(NotificationManager::instance());
    ASSERT_TRUE(manager);
    manager->Notify("org.webosports.test", 0, "", "", "title", "body", QUrl(), "", QUrl(), 0, false, 0, -1);
    manager->Notify("org.webosports.test", 0, "", "", "title", "body", QUrl(), "", QUrl(), 0, false, 0, -1);
    ASSERT_EQ(manager->notificationIds().count(), 2);
    QPointer<Notification> notification(manager->notification(manager->notificationIds().first()));
    ASSERT_TRUE(notification);

    delete static_cast<QObject *>(manager.data());
    EXPECT_FALSE(manager);
    EXPECT_FALSE(notification);
}
