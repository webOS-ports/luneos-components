TEMPLATE = aux

uri = LuneOS.Bluetooth
installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

QML_FILES = *.qml

QMLDIR_FILE = qmldir

OTHER_FILES += $$QML_FILES $$QMLDIR_FILE

qmldir_file.path = $$installPath
qmldir_file.files = $$QMLDIR_FILE
qml_files.path = $$installPath
qml_files.files = $$QML_FILES

INSTALLS += qmldir_file qml_files 

