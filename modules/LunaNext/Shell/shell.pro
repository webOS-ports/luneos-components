TEMPLATE = lib
TARGET = lunanext-shell-qml

QT += qml quick quick-private
CONFIG += qt plugin

CONFIG += link_pkgconfig
PKGCONFIG += luna-service2 luna-service2++ LunaSysMgrCommon

TARGET = $$qtLibraryTarget($$TARGET)
uri = LunaNext.Shell

HEADERS += \
    plugin.h \
    reticleitem.h \
    fpscounter.h \
    gesturehandler.h \
    devicekeyhandler.h \
    volumekeys.h \
    quickutils.h \
    inversemouseareatype.h

SOURCES += \
    plugin.cpp \
    reticleitem.cpp \
    fpscounter.cpp \
    gesturehandler.cpp \
    devicekeyhandler.cpp \
    volumekeys.cpp \
    quickutils.cpp \
    inversemouseareatype.cpp

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath

qmldir_file.path = $$installPath
qmldir_file.files = qmldir

INSTALLS += target qmldir_file
