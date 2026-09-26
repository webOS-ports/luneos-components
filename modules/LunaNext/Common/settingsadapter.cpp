/*
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2016 Herman van Hazendonk <github.com@herrie.org>
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

#include <Settings.h>

#include "settingsadapter.h"

#include <QRect>
#include <QString>
#include <QStringList>

namespace luna
{

SettingsAdapter::SettingsAdapter()
{
}

bool SettingsAdapter::tabletUi() const
{
    return Settings::LunaSettings()->tabletUi;
}

bool SettingsAdapter::showNotificationsAtTop() const
{
    return Settings::LunaSettings()->showNotificationsAtTop;
}

qreal SettingsAdapter::dpi() const
{
    return Settings::LunaSettings()->dpi;
}

int SettingsAdapter::displayWidth() const
{
    return Settings::LunaSettings()->displayWidth;
}

int SettingsAdapter::displayHeight() const
{
    return Settings::LunaSettings()->displayHeight;
}

bool SettingsAdapter::displayFps() const
{
    return Settings::LunaSettings()->debug_piranhaDisplayFps;
}

/*
 * The panel's shape, as Settings carries it: a ';' separated list of "x y w h"
 * rectangles, and a ';' separated list of four radii. Parsed here rather than in
 * luna-sysmgr-common because QRect is the shape QML actually wants, and because
 * a malformed adaptation should degrade to "no cutouts" rather than to a
 * rectangle nobody can explain.
 *
 * A field that is not an integer, or a rect with anything other than four
 * fields, is dropped with a warning: one bad entry in a hand-written deviceinfo
 * must not take the rest of the list with it, and a silently empty rect at
 * 0,0,0,0 would be indistinguishable from a corner cutout of no width.
 */
static QList<int> parseIntList(const QString &raw, const char *what)
{
	QList<int> out;

	const QStringList fields = raw.split(QLatin1Char(';'), Qt::SkipEmptyParts);
	for (const QString &field : fields) {
		bool ok = false;
		const int v = field.trimmed().toInt(&ok);
		if (!ok) {
			qWarning("SettingsAdapter: %s: '%s' is not a number, ignoring it",
			         what, qUtf8Printable(field));
			continue;
		}
		out.append(v);
	}

	return out;
}

QVariantList SettingsAdapter::displayCutouts() const
{
	QVariantList out;

	const QString raw = QString::fromStdString(Settings::LunaSettings()->displayCutouts);
	const QStringList rects = raw.split(QLatin1Char(';'), Qt::SkipEmptyParts);

	for (const QString &rect : rects) {
		const QStringList f = rect.simplified().split(QLatin1Char(' '), Qt::SkipEmptyParts);
		if (f.count() != 4) {
			qWarning("SettingsAdapter: cutout '%s' is not \"x y w h\", ignoring it",
			         qUtf8Printable(rect));
			continue;
		}

		bool ok = true;
		int v[4];
		for (int i = 0; i < 4; ++i) {
			bool fieldOk = false;
			v[i] = f.at(i).toInt(&fieldOk);
			ok = ok && fieldOk;
		}
		if (!ok) {
			qWarning("SettingsAdapter: cutout '%s' has a non-numeric field, ignoring it",
			         qUtf8Printable(rect));
			continue;
		}
		// A zero-sized cutout costs the layout nothing and would only make the
		// shell reason about an obstacle that is not there.
		if (v[2] <= 0 || v[3] <= 0) {
			qWarning("SettingsAdapter: cutout '%s' has no area, ignoring it",
			         qUtf8Printable(rect));
			continue;
		}

		out.append(QVariant::fromValue(QRect(v[0], v[1], v[2], v[3])));
	}

	return out;
}

/*
 * Four radii, top-left, top-right, bottom-right, bottom-left - the order
 * gmobile's GmCornerPosition uses, so that a panel definition taken from there
 * transcribes without reshuffling. A single value is accepted and applied to all
 * four corners, which is what almost every phone actually has and what gmobile's
 * own deprecated "border-radius" meant.
 */
QVariantList SettingsAdapter::displayCornerRadii() const
{
	QVariantList out;

	const QString raw = QString::fromStdString(Settings::LunaSettings()->displayCornerRadii);
	QList<int> radii = parseIntList(raw, "corner radius");

	if (radii.count() == 1)
		radii = QList<int>() << radii.at(0) << radii.at(0) << radii.at(0) << radii.at(0);

	if (radii.isEmpty())
		return out;

	if (radii.count() != 4) {
		qWarning("SettingsAdapter: CornerRadii needs one or four values, got %d, ignoring them",
		         int(radii.count()));
		return out;
	}

	for (int r : radii)
		out.append(QVariant::fromValue(r < 0 ? 0 : r));

	return out;
}

bool SettingsAdapter::showReticle() const
{
    return Settings::LunaSettings()->showReticle;
}

int SettingsAdapter::splashIconSize() const
{
    return Settings::LunaSettings()->splashIconSize;
}

int SettingsAdapter::gestureAreaHeight() const
{
    return Settings::LunaSettings()->gestureAreaHeight;
}

int SettingsAdapter::positiveSpaceTopPadding() const
{
    return Settings::LunaSettings()->positiveSpaceTopPadding;
}

int SettingsAdapter::positiveSpaceBottomPadding() const
{
    return Settings::LunaSettings()->positiveSpaceBottomPadding;
}

QString SettingsAdapter::fontStatusBar() const
{
    return QString::fromStdString(Settings::LunaSettings()->fontStatusBar);
}

QString SettingsAdapter::lunaSystemResourcesPath() const
{
    return QString::fromStdString(Settings::LunaSettings()->lunaSystemResourcesPath);
}

bool SettingsAdapter::hasVolumeButton() const
{
    return Settings::LunaSettings()->hasVolumeButton;
}

bool SettingsAdapter::hasPowerButton() const
{
    return Settings::LunaSettings()->hasPowerButton;
}

bool SettingsAdapter::hasHomeButton() const
{
    return Settings::LunaSettings()->hasHomeButton;
}

bool SettingsAdapter::hasBrightnessControl() const
{
    return Settings::LunaSettings()->hasBrightnessControl;
}

/* Below is used for sounds */

QString SettingsAdapter::lunaSystemSoundsPath() const
{
    return QString::fromStdString(Settings::LunaSettings()->lunaSystemSoundsPath);
}

QString SettingsAdapter::lunaDefaultAlertSound() const
{
    return QString::fromStdString(Settings::LunaSettings()->lunaDefaultAlertSound);
}

QString SettingsAdapter::lunaDefaultRingtoneSound() const
{
    return QString::fromStdString(Settings::LunaSettings()->lunaDefaultRingtoneSound);
}

QString SettingsAdapter::lunaSystemSoundAppClose() const
{
    return QString::fromStdString(Settings::LunaSettings()->lunaSystemSoundAppClose);
}

QString SettingsAdapter::lunaSystemSoundScreenCapture() const
{
    return QString::fromStdString(Settings::LunaSettings()->lunaSystemSoundScreenCapture);
}

int SettingsAdapter::notificationSoundDuration() const
{
    return Settings::LunaSettings()->notificationSoundDuration;
}

} // namespace luna
