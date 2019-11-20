
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

import QtQuick 2.9
import QtWebEngine 1.6
import Qt.labs.settings 1.0

WebEngineView {
    id: webViewItem

    UserAgent
    {
        id: userAgent
    }
	
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
	
    settings.javascriptEnabled: true
    settings.localStorageEnabled:true
    settings.localContentCanAccessFileUrls: true
    settings.javascriptCanAccessClipboard: true
    settings.localContentCanAccessRemoteUrls: true
    settings.pluginsEnabled: true
    
    profile.httpUserAgent: userAgent.defaultUA

    Component.onCompleted: {
        // these settings are only available on our custom WebEngine for LuneOS
        if( typeof webViewItem.settings.standardFontFamily !== 'undefined' )
            settings.standardFontFamily = "Prelude";
        if( typeof webViewItem.settings.fixedFontFamily !== 'undefined' )
            settings.fixedFontFamily = "Courier new";
        if( typeof webViewItem.settings.serifFontFamily !== 'undefined' )
            settings.serifFontFamily = "Times New Roman";
        if( typeof webViewItem.settings.cursiveFontFamily !== 'undefined' )
            settings.cursiveFontFamily = "Prelude";
    }
}

