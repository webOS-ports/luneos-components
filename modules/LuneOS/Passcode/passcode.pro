# QML only: the pattern grid and the PIN pad that both the lock screen and
# the places a passcode is set use, so the two agree on what was entered.
TEMPLATE = aux

uri = LuneOS.Passcode
installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

QML_FILES = PatternLockGrid.qml \
            PinButton.qml \
            PinPad.qml

RESOURCE_FILES = images/icon-delete.png \
                 images/pin-key-highlight.png

QMLDIR_FILE = qmldir

OTHER_FILES += $$QML_FILES $$QMLDIR_FILE $$RESOURCE_FILES

qmldir_file.path = $$installPath
qmldir_file.files = $$QMLDIR_FILE
qml_files.path = $$installPath
qml_files.files = $$QML_FILES
resources_files.path = $$installPath/images
resources_files.files = $$RESOURCE_FILES

INSTALLS += qmldir_file qml_files resources_files
