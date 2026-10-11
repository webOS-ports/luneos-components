# QML only: helpers over LuneOS.Service's LunaService for what every app
# asks the system for - is a service there, the system preferences, start
# an app or open a URL - with one name per service (Services.js).
#
# A module of its own, not more types in LuneOS.Service: nearly every file
# imports that one, and a new name there shadows any file of the same name
# next to an importer - the shell's Connectors/ServiceStatus.qml stopped
# loading, and with it the whole shell, when ServiceStatus was added there.
TEMPLATE = aux

uri = LuneOS.System
installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

QML_FILES = AppLauncher.qml \
            ServiceStatus.qml \
            SystemPreferences.qml

JS_FILES = Services.js

QMLDIR_FILE = qmldir

OTHER_FILES += $$QML_FILES $$JS_FILES $$QMLDIR_FILE

qmldir_file.path = $$installPath
qmldir_file.files = $$QMLDIR_FILE
qml_files.path = $$installPath
qml_files.files = $$QML_FILES
js_files.path = $$installPath
js_files.files = $$JS_FILES

INSTALLS += qmldir_file qml_files js_files
