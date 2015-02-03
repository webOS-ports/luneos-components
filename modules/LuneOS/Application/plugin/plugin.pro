unix {
    CONFIG += link_pkgconfig
    PKGCONFIG += luna-service2
}

TEMPLATE = lib
TARGET = ../LuneOSApplication

QT += core-private qml qml-private quick quick-private gui-private
CONFIG += qt plugin

CONFIG += c++11 no_keywords

TARGET = $$qtLibraryTarget($$TARGET)
uri = LuneOS.Application

LIBS += -lluna-service2++

HEADERS += \
    plugin.h \
    applicationwindow.h \
    db8model.h

SOURCES += \
    plugin.cpp \
    applicationwindow.cpp \
    db8model.cpp

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath
INSTALLS += target
