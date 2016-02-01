TEMPLATE = aux

uri = LuneOS.Telephony
installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

JS_FILES = libphonenumber.js  libphonenumber-wrapper.js

PHONENUMBER_FILES = phonenumber.js/*.js

RESOURCE_FILES = geocoding/*.json

QMLDIR_FILE = qmldir

OTHER_FILES += $$JS_FILES $$QMLDIR_FILE $$RESOURCE_FILES $$PHONENUMBER_FILES 

qmldir_file.path = $$installPath
qmldir_file.files = $$QMLDIR_FILE
js_files.path = $$installPath
js_files.files = $$JS_FILES
phonenumber_files.path = $$installPath/phonenumber.js
phonenumber_files.files = $$PHONENUMBER_FILES
resources_files.path = $$installPath/geocoding
resources_files.files = $$RESOURCE_FILES

INSTALLS += qmldir_file js_files resources_files phonenumber_files

