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

#ifndef CAPTUREFILE_H
#define CAPTUREFILE_H

#include <QByteArray>
#include <QString>

/*
 * Writes `data` to a file that did not exist before, at `path` or, when
 * that is taken, at the first free "<name>-1.<ext>", "<name>-2.<ext>", ...
 * next to it, and returns the path written; an empty string when none could
 * be written (nothing is left behind then).
 *
 * The camera app names its pictures to the second, so two shots in one
 * second had the same name and the second replaced the first. The file is
 * created with O_EXCL and O_NOFOLLOW: a symlink in its place is not
 * written through either.
 */
QString writeNewCaptureFile(const QString &path, const QByteArray &data);

#endif // CAPTUREFILE_H
