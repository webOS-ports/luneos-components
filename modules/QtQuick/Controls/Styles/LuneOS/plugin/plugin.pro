TEMPLATE = lib
TARGET = ../luneosstyleplugin

QT += qml quick
CONFIG += qt plugin

TARGET = $$qtLibraryTarget($$TARGET)
uri = QtQuick.Controls.Styles.LuneOS

HEADERS += \
    plugin.h \

SOURCES += \
    plugin.cpp \

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath
INSTALLS += target
