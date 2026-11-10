/*
 * (c) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef FAKE_LS2_H
#define FAKE_LS2_H

#include <string>
#include <vector>

struct FakeBus
{
    std::vector<std::string> events;
    bool registerOk = true;
    unsigned long lastToken = 0;

    void reset()
    {
        events.clear();
        registerOk = true;
    }
};

FakeBus &fakeBus();

#endif
