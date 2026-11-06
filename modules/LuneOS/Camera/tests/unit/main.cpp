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

#include <QCoreApplication>
#include <QThreadPool>

#include <gst/gst.h>

/* BarcodeScanner hands its results back through the event loop, so the tests
 * run inside an application object. The DroidCameraBin tests build real
 * GStreamer bins. */
int main(int argc, char **argv)
{
    gst_init(&argc, &argv);
    QCoreApplication app(argc, argv);
    /* Pool threads live for the whole run. Qt joins a thread with
     * pthread_clockjoin_np(), which ThreadSanitizer does not intercept, so
     * to TSan a joined thread stays alive; the next one started on its
     * pthread handle stops the run with "CHECK failed" in
     * sanitizer_thread_registry.cpp. With the default expiry a worker would
     * exit and be joined between tests. The tests wait for the pool with
     * drainPool(), not waitForDone(), for the same reason. */
    QThreadPool::globalInstance()->setExpiryTimeout(-1);
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
