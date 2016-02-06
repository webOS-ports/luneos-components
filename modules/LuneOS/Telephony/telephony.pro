TEMPLATE = aux

uri = LuneOS.Telephony
installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

JS_FILES = libphonenumber-wrapper.js

RESOURCE_FILES = geocoding/*.json

QMLDIR_FILE = qmldir

OTHER_FILES += $$JS_FILES $$QMLDIR_FILE $$RESOURCE_FILES 

qmldir_file.path = $$installPath
qmldir_file.files = $$QMLDIR_FILE
js_files.path = $$installPath
js_files.files = $$JS_FILES
resources_files.path = $$installPath/geocoding
resources_files.files = $$RESOURCE_FILES

INSTALLS += qmldir_file js_files resources_files 

