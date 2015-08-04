/*
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; see the file COPYING.  If not, see
 * <http://www.gnu.org/licenses/>.
 *
 */

var values = []

function selectedValues() {
    return values
}

function countValues() {
    return values.length

}

function isSelected(value) {
    return (values.indexOf(value) != -1)
}

function addValue(value) {
    if (values.indexOf(value) != -1)
        return
    values.push(value)
}

function removeValue(value) {
    var index = values.indexOf(value)

    if (index == -1)
        return
    values.splice(index, 1)
}
