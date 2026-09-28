/*
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2015 Nikolay Nizov <nizovn@gmail.com>
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

#ifndef LEDS_H_
#define LEDS_H_

#include <QObject>
#include <QColor>
#include <CoreNaviLeds.h>

namespace luna
{

class LedsAdapter : public QObject
{
    Q_OBJECT

public:
    /*
     * The LED masks nyx understands, so that a caller names an LED instead of
     * repeating a bare constant. Bound to nyx's own values rather than
     * redeclared with literals, so they cannot drift from what nyx expects.
     *
     * These are masks: the LED controller matches them rather than comparing
     * them, so a device with a single RGB LED lights it for CenterLed and for
     * any combination that includes it.
     */
    enum Led {
        NoLed     = NYX_LED_CONTROLLER_NONE_LED,
        LeftLed   = NYX_LED_CONTROLLER_LEFT_LED,
        CenterLed = NYX_LED_CONTROLLER_CENTER_LED,
        RightLed  = NYX_LED_CONTROLLER_RIGHT_LED,
    };
    Q_ENUM(Led)

    /*
     * The LED to pass to ledPulsate() for a phone's notification LED. Named
     * for the role rather than for the hardware position, which is what a
     * caller announcing a notification means.
     */
    Q_PROPERTY(Led notificationLed READ notificationLed CONSTANT)

    LedsAdapter();

    Led notificationLed() const;
    Q_INVOKABLE void stopAll() const;
    Q_INVOKABLE void ledPulsate(int led, int brightness, int startDelay, int FadeIn, int FadeOut, int FadeOutDelay, int RepeatDelay, int repeat) const;
    Q_INVOKABLE void ledSet(int brightness) const;

    /*
     * Colour applied to every effect started after this call, until it is
     * changed or cleared. Kept separate from the effect calls so that none of
     * them has to grow three more arguments, and so a caller that does not care
     * about colour - everything that used this adapter before - keeps working
     * unchanged.
     *
     * An invalid QColor clears the colour, which is the same as calling
     * clearColor(): the LED then behaves as it did before colour existed, which
     * is what a single-colour LED wants.
     *
     * nyx scales colour by the effect's brightness, so setting a colour without
     * also passing a non-zero brightness to the effect leaves the LED dark.
     */
    Q_INVOKABLE void setColor(const QColor &color) const;
    Q_INVOKABLE void clearColor() const;

private:
    CoreNaviLeds* m_leds;
};

} // namespace luna

#endif
