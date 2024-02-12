TEMPLATE = lib
TARGET = ../LuneOSComponents

QT += core-private qml qml-private quick quick-private
CONFIG += qt plugin

CONFIG += qmltypes
QML_IMPORT_NAME = "LuneOS.Components"
QML_IMPORT_MAJOR_VERSION = "1"

TARGET = $$qtLibraryTarget($$TARGET)
uri = LuneOS.Components

HEADERS += \
    plugin.h

SOURCES += \
    plugin.cpp

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath
INSTALLS += target
