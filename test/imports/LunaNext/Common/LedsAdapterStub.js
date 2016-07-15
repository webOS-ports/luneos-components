/*
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

.pragma library

function LedsAdapter() {
    console.log("LedsAdapter stub: LedsAdapter always return true");
    return true;
}

function stopAll() {
    console.log("LedsAdapter stub: stopAll always return true");
    return true;
}

function ledPulsate(led, brightness, startDelay, FadeIn, FadeOut, FadeOutDelay, RepeatDelay, repeat) {
    console.log("LedsAdapter stub: ledPulsate always return true");
    return true;
}

function ledSet(brightness) {
    console.log("LedsAdapter stub: ledSet always return true");
    return true;
}
