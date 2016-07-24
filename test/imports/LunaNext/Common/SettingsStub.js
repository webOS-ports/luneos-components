/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
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

var isTestEnvironment = true;

/* A500 alike
var tabletUi = true;
var displayWidth = 1280;
var displayHeight = 800;
var dpi = 149;
var gridUnit = 10;
var compatDpi = 149;
/**/
/*GNex alike
var tabletUi = false;
var displayWidth = 720;
var displayHeight = 1280;
var dpi = 264;
var gridUnit = 18;
var compatDpi = 180;
/**/
/* N7 alike
var tabletUi = true;
var displayWidth = 1280;
var displayHeight = 800;
var dpi = 216;
var gridUnit = 14;
var compatDpi = 180;
/**/
/* TP alike
var tabletUi = true;
var displayWidth = 1024;
var displayHeight = 768;
var dpi = 132;
var compatDpi = 132;
var gridUnit = 10;
/**/
/* N4 alike
var tabletUi = false;
var displayWidth = 768;
var displayHeight = 1280;
var dpi = 264;
var gridUnit = 18;
var compatDpi = 180;
/**/
/* For desktop debug */
var tabletUi = false;
var displayWidth = 600;
var displayHeight = 800;
var dpi = 148;
var gridUnit = 10;
var compatDpi = 180;
/**/

var displayFps = true;
var fontStatusBar = "Prelude"
var showReticle = false;

// not used
var lunaSystemResourcesPath = "./resourcesPath";
var splashIconSize = 64;
var gestureAreaHeight = 64;
var positiveSpaceTopPadding = 0;
var positiveSpaceBottomPadding = 0;
var hasBrightnessControl = true;

var layoutScale = dpi/132;
