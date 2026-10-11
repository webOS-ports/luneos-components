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
    /* Pool threads live for the whole run. With the default expiry a worker
     * exits between tests and the next one starts on its pthread handle,
     * which a ThreadSanitizer runtime built for another glibc than the
     * sysroot's mistakes for a thread still alive (CHECK failed in
     * sanitizer_thread_registry.cpp). */
    QThreadPool::globalInstance()->setExpiryTimeout(-1);
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
