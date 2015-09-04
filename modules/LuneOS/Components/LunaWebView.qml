
/*
* Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
* Copyright (C) 2014 Herman van Hazendonk <github.com@herrie.org>
* Copyright (C) 2014 Christophe Chapuis <chris.chapuis@gmail.com>
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
import QtWebKit 3.0
import QtWebKit.experimental 1.0
import QtQuick 2.0
import LuneOS.Components 1.0

WebView {
    id: webViewItem

    experimental.preferences.navigatorQtObjectEnabled: true
    experimental.preferences.localStorageEnabled: true
    experimental.preferences.offlineWebApplicationCacheEnabled: true
    experimental.preferences.webGLEnabled: true
    experimental.preferences.developerExtrasEnabled: true
    experimental.preferences.webAudioEnabled: true
    experimental.preferences.dnsPrefetchEnabled: true

    experimental.preferences.standardFontFamily: "Prelude"
    experimental.preferences.fixedFontFamily: "Courier new"
    experimental.preferences.serifFontFamily: "Times New Roman"
    experimental.preferences.cursiveFontFamily: "Prelude"

    experimental.authenticationDialog: AuthenticationDialog {
        serverURL: webViewItem.url
        hostname: model.hostname
        onAccepted: {
            //TODO: Need to implement password manager using KeyManager where possible
            if (savePwd) {
                //TODO Function to call and do the password management
            }
            model.accept(username, pass);
        }
    }
    experimental.certificateVerificationDialog: CertDialog {
        onViewCertificate: { /*TODO*/ }
        onTrust: {
            model.accept();
            if(always) { /*TODO*/ }
        }
        onReject: {
            model.reject();
            webview.stop();
        }
    }
    experimental.proxyAuthenticationDialog: ProxyAuthenticationDialog {
        hostname: model.hostname
        port: model.port
        onAccepted: {
            //TODO: Need to implement password manager using KeyManager where possible
            if (savePwd) {
                //TODO Function to call and do the password management
            }
            model.accept(username, pass);
        }
    }
    experimental.alertDialog: AlertDialog {
        message: model.message
        onAccepted: model.dismiss();
    }
    experimental.confirmDialog: ConfirmDialog {
        message: model.message
        onAccepted: model.accept();
        onRejected: model.reject();
    }
    experimental.promptDialog: PromptDialog {
        message: model.message
        defaultValue: model.defaultValue
        onAccepted: model.accept(input.text);
        onRejected: model.reject();
    }
    experimental.filePicker: FilePicker {
        fileModel: model
    }
    experimental.itemSelector: ItemSelector {
        selectorModel: model;
    }
    experimental.databaseQuotaDialog: Item {
        Component.onCompleted: {
            console.log("Database quota extension request:");
            console.log(" databaseName: " + model.databaseName);
            console.log(" displayName: " + model.displayName);
            console.log(" currentQuota: " + model.currentQuota);
            console.log(" currentOriginUsage: " + model.currentOriginUsage);
            console.log(" expectedUsage: " + model.expectedUsage);
            if( model.securityOrigin ) {
                console.log(" securityOrigin:");
                console.log("   scheme: " + model.securityOrigin.scheme);
                console.log("   host: " + model.securityOrigin.host);
                console.log("   port: " + model.securityOrigin.port);
            }

            // we allow 5 MB for now
            model.accept(5 * 1024 * 1024);
        }
    }
}

