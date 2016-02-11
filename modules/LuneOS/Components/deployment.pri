uri = LuneOS.Components
installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

QML_FILES = Page.qml \
            AlertDialog.qml \
            AuthenticationDialog.qml \
            CertDialog.qml \
            ClippedImage.qml \
            ConfirmDialog.qml \
            ContextMenuExtras.qml \
            DialogButton.qml \
            DialogLineInput.qml \
            Dialog.qml \
            FilePicker.qml \
            ItemSelector.qml \
            LunaWebView.qml \
            LunaWebEngineView.qml \
            PermissionDialog.qml \
            PromptDialog.qml \
            ProxyAuthenticationDialog.qml \
            Tweak.qml \
            WebEngineDialog.qml \
            WebEngineDialogButton.qml

JS_FILES = js/MultiSelect.js

RESOURCE_FILES = images/button-up-center.png images/button-up-left.png images/button-up-right.png \
                 images/input-default-focus-center.png images/input-default-focus-left.png images/input-default-focus-right.png \
                 images/checkbox-checked.png images/checkbox-unchecked.png \
                 images/dialog-center-bottom.png images/dialog-center-middle.png images/dialog-center-top.png \
                 images/dialog-left-bottom.png images/dialog-left-middle.png images/dialog-left-top.png \
                 images/dialog-right-bottom.png images/dialog-right-middle.png images/dialog-right-top.png \
                 images/icon-file.png images/icon-folder.png images/icon-warning.png

QMLDIR_FILE = qmldir

OTHER_FILES += $$QML_FILES $$JS_FILES $$QMLDIR_FILE $$RESOURCE_FILES

qmldir_file.path = $$installPath
qmldir_file.files = $$QMLDIR_FILE
qml_files.path = $$installPath
qml_files.files = $$QML_FILES
js_files.path = $$installPath/js
js_files.files = $$JS_FILES
resources_files.path = $$installPath/images
resources_files.files = $$RESOURCE_FILES

INSTALLS += qmldir_file qml_files js_files resources_files
