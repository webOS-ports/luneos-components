unix {
    CONFIG += link_pkgconfig
    PKGCONFIG += luna-service2 webos-application
}

TEMPLATE = lib
TARGET = ../LuneOSService

QT += qml quick
CONFIG += qt plugin

CONFIG += c++11 no_keywords

TARGET = $$qtLibraryTarget($$TARGET)
uri = LuneOS.Service

LIBS += -lluna-service2++

HEADERS += \
    plugin.h \
    lunaserviceadapter.h \
    db8model.h

SOURCES += \
    plugin.cpp \
    lunaserviceadapter.cpp \
    db8model.cpp

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath
INSTALLS += target
