TEMPLATE = lib
TARGET = lunanext-common-qml

QT += qml quick
CONFIG += qt plugin

CONFIG += link_pkgconfig
PKGCONFIG += luna-service2 luna-service2++ LunaSysMgrCommon

TARGET = $$qtLibraryTarget($$TARGET)
uri = LunaNext.Common

HEADERS += \
    plugin.h \
    settingsadapter.h \
    ledsadapter.h \
    fontutils.h \
    fileutils.h \
    eventtype.h \
    units.h

SOURCES += \
    plugin.cpp \
    settingsadapter.cpp \
    ledsadapter.cpp \
    fontutils.cpp \
    fileutils.cpp \
    eventtype.cpp \
    units.cpp

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath
INSTALLS += target
