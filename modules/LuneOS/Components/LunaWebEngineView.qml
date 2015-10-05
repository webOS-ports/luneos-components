
/*
* Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
* Copyright (C) 2015 Christophe Chapuis <chris.chapuis@gmail.com>
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

import QtQuick 2.1
import QtWebEngine 1.1
import QtWebEngine.experimental 1.0
import Qt.labs.settings 1.0

WebEngineView {
    id: webViewItem

    PermissionDialog
    {
        id: permDialog
        view: webViewItem
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        z: 3
    }

    onFeaturePermissionRequested: {
        permDialog.securityOrigin = securityOrigin;
        permDialog.requestedFeature = feature;
        permDialog.visible = true
    }
	
	experimental
    {
        extraContextMenuEntriesComponent: ContextMenuExtras {}
    }
	
	settings.javascriptEnabled: true
    settings.localStorageEnabled:true
    settings.localContentCanAccessFileUrls: true
    settings.javascriptCanAccessClipboard: true
    settings.localContentCanAccessRemoteUrls: true
}

