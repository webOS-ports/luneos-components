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

.pragma library
.import QtCore as Core

/*
 * Where an app keeps its files. The QML runner is one program for every QML
 * app, so QSettings' organisation and application pair would put every app's
 * preferences in the runner's one file; each app's is named by its id:
 *
 *   import QtCore
 *   import LuneOS.Components 1.0
 *   Settings {
 *       location: AppFiles.preferencesFile("org.webosports.app.pdf")
 *       category: "viewer"
 *       property bool nightMode: false
 *   }
 *
 * A function rather than a Settings type with an appId of its own: Settings
 * saves every property declared on it, and the id would end up in the file.
 */

// The file: URL of <config>/<appId>/preferences.ini.
function preferencesFile(appId) {
    if (!appId)
        console.warn("AppFiles.preferencesFile: no app id");
    return Core.StandardPaths.writableLocation(Core.StandardPaths.GenericConfigLocation)
            + "/" + appId + "/preferences.ini";
}
