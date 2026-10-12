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

/*
 * One spelling for each of the services every app talks to.
 *
 * The apps and the shell had grown four spellings of the bus, two of the
 * system service and four of the application manager. On the Q25 all of
 * these answer, both as an app and at the shell's trust level:
 *   bus                 com.webos.service.bus, com.palm.bus, com.palm.lunabus
 *   system service      com.webos.service.systemservice, com.palm.systemservice
 *   application manager com.webos.service.applicationmanager, and the
 *                       com.webos.service.applicationManager and
 *                       com.webos.applicationManager aliases
 * except com.webos.lunabus, which does not exist, and
 * com.palm.applicationManager, which is the older application manager with
 * a different API (it takes "appId", not "id"; it refused the shell's
 * getAppInfo).
 *
 * The names below are the webOS OSE ones the services register under
 * first; the others are aliases. Access control is checked per name, on
 * the caller's side and on the service's reply side, so a new caller should
 * use these rather than pick an alias that happens to work for it.
 *
 * One exception: opening a URL. The OSE application manager has no "open"
 * ("Unknown method" for every spelling of it), so a call there does nothing.
 * The older com.palm.applicationManager has it: given a "target" it finds
 * the handler in /etc/palm/command-resource-handlers.json and starts it.
 */

var bus = "luna://com.webos.service.bus";
var systemService = "luna://com.webos.service.systemservice";
var applicationManager = "luna://com.webos.service.applicationmanager";
// Only for "open": see above.
var resourceHandler = "luna://com.palm.applicationManager";
