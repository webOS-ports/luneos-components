uri = LunaOS.Components
installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

QML_FILES = $$system(ls *.qml)
JS_FILES = $$system(ls *.js)
QMLDIR_FILE = qmldir

OTHER_FILES += $$QML_FILES $$JS_FILES $$QMLDIR_FILE

qmldir_file.path = $$installPath
qmldir_file.files = $$QMLDIR_FILE
qml_files.path = $$installPath
qml_files.files = $$QML_FILES
js_files.path = $$installPath
js_files.files = $$JS_FILES

INSTALLS += qmldir_file qml_files js_files
