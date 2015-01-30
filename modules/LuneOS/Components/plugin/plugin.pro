TEMPLATE = lib
TARGET = ../LunaOSComponents

QT += core-private qml qml-private quick quick-private
CONFIG += qt plugin

TARGET = $$qtLibraryTarget($$TARGET)
uri = LuneOS.Components

HEADERS += \
	plugin.h

SOURCES += \
	plugin.cpp

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath
INSTALLS += target
