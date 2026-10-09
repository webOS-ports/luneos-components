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

#include <QGuiApplication>
#include <QRect>
#include <QScreen>
#include <QSize>
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

/*
 * DisplayWidth/DisplayHeight of 0 mean "not measured": luneos-device-config
 * leaves them at the template's 0 when it finds no panel size, which is every
 * virtual machine - there the output mode is only settled once surface-manager
 * has the display, long after the config was generated (vmwgfx still reports
 * 1280x800 then, and the output comes up at 1920x1080).
 *
 * Passing the 0 on gave every QML app a 0x0 window that Qt never exposes, and
 * any guessed size that differs from the output makes the compositor scale the
 * card, so touches land in the wrong place. Use the screen this process
 * actually has instead: in an app that is the compositor's wl_output, in the
 * compositor itself the DRM output.
 */
static QSize screenSize()
{
    const QScreen *screen = QGuiApplication::primaryScreen();
    return screen ? screen->size() : QSize(0, 0);
}

int SettingsAdapter::displayWidth() const
{
    const int width = Settings::LunaSettings()->displayWidth;
    return width > 0 ? width : screenSize().width();
}

int SettingsAdapter::displayHeight() const
{
    const int height = Settings::LunaSettings()->displayHeight;
    return height > 0 ? height : screenSize().height();
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
 *
 * The separator is an argument because both levels of the cutout syntax are the
 * same job: the list of rectangles is split on ';' and each rectangle on ' '.
 */
static QList<int> parseIntList(const QString &raw, QChar separator, const char *what)
{
	QList<int> out;

	const QStringList fields = raw.split(separator, Qt::SkipEmptyParts);
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

/*
 * The avoidance rectangles, as rect values QML can read directly:
 *
 *   Cutouts="324 0 72 102"            ->  [ { x: 324, y: 0, width: 72, height: 102 } ]
 *   Cutouts="0 0 40 96;505 21 70 71"  ->  [ { x: 0,   y: 0,  width: 40, height: 96  },
 *                                           { x: 505, y: 21, width: 70, height: 71  } ]
 *
 * so a consumer writes cutouts[0].x, .y, .width, .height. An absent or empty key
 * gives an empty list, which is the normal case - a panel with no cutouts.
 */
QVariantList SettingsAdapter::displayCutouts() const
{
	QVariantList out;

	const QString raw = QString::fromStdString(Settings::LunaSettings()->displayCutouts);
	const QStringList rects = raw.split(QLatin1Char(';'), Qt::SkipEmptyParts);

	for (const QString &rect : rects) {
		const QList<int> f = parseIntList(rect.simplified(), QLatin1Char(' '), "cutout");

		// Covers both a rect with the wrong number of fields and one whose
		// fields did not all parse - parseIntList has already said which.
		if (f.count() != 4) {
			qWarning("SettingsAdapter: cutout '%s' is not four numbers \"x y w h\", ignoring it",
			         qUtf8Printable(rect));
			continue;
		}
		// A zero-sized cutout costs the layout nothing and would only make the
		// shell reason about an obstacle that is not there.
		if (f.at(2) <= 0 || f.at(3) <= 0) {
			qWarning("SettingsAdapter: cutout '%s' has no area, ignoring it",
			         qUtf8Printable(rect));
			continue;
		}

		out.append(QVariant::fromValue(QRect(f.at(0), f.at(1), f.at(2), f.at(3))));
	}

	return out;
}

/*
 * Four radii, top-left, top-right, bottom-right, bottom-left - the order
 * gmobile's GmCornerPosition uses, so that a panel definition taken from there
 * transcribes without reshuffling. A single value is accepted and applied to all
 * four corners, which is what almost every phone actually has and what gmobile's
 * own deprecated "border-radius" meant:
 *
 *   CornerRadii="75"           ->  [ 75, 75, 75, 75 ]
 *   CornerRadii="10;20;30;40"  ->  [ 10, 20, 30, 40 ]
 *
 * a plain list of ints, so a consumer writes cornerRadii[0] for the top-left.
 * Empty when the key is absent, or when it holds neither one value nor four.
 */
QVariantList SettingsAdapter::displayCornerRadii() const
{
	QVariantList out;

	const QString raw = QString::fromStdString(Settings::LunaSettings()->displayCornerRadii);
	QList<int> radii = parseIntList(raw, QLatin1Char(';'), "corner radius");

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
