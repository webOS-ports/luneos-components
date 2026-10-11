# QML only: the rows, fields and page pieces that settings-style apps
# (Settings, Messwerk, ...) used to copy from one another.
TEMPLATE = aux

uri = LuneOS.Forms
installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

QML_FILES = AppHeader.qml \
            AppPage.qml \
            AppWindow.qml \
            Colors.qml \
            ExplanationText.qml \
            FormGroup.qml \
            FormTextField.qml \
            HorizontalSeparator.qml \
            LabelAndSelector.qml \
            LabelAndSlider.qml \
            LabelAndSwitch.qml \
            LabelAndTextField.qml \
            LabelAndValue.qml \
            ListPicker.qml \
            ListPickerPopup.qml \
            ServiceUnavailableNotice.qml \
            SettingsPageContent.qml \
            StatusNotice.qml

RESOURCE_FILES = images/toolbar-light.png

QMLDIR_FILE = qmldir

OTHER_FILES += $$QML_FILES $$QMLDIR_FILE $$RESOURCE_FILES

qmldir_file.path = $$installPath
qmldir_file.files = $$QMLDIR_FILE
qml_files.path = $$installPath
qml_files.files = $$QML_FILES
resources_files.path = $$installPath/images
resources_files.files = $$RESOURCE_FILES

INSTALLS += qmldir_file qml_files resources_files
