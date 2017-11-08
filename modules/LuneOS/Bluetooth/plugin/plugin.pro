TEMPLATE = lib
TARGET = ../LuneOSBluetooth

QT += qml quick BluezQt dbus
CONFIG += qt plugin

CONFIG += c++11 no_keywords

TARGET = $$qtLibraryTarget($$TARGET)
uri = LuneOS.Bluetooth

HEADERS += \
    plugin.h \
    luneosbtagent.h \
    luneosbtrequest.h

SOURCES += \
    plugin.cpp \
    luneosbtagent.cpp \
    luneosbtrequest.cpp

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath
INSTALLS += target
