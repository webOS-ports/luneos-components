TEMPLATE = lib
TARGET = ../LuneOSComponents

QT += core-private qml qml-private quick quick-private svg
CONFIG += qt plugin

CONFIG += qmltypes
QML_IMPORT_NAME = "LuneOS.Components"
QML_IMPORT_MAJOR_VERSION = "1"

TARGET = $$qtLibraryTarget($$TARGET)
uri = LuneOS.Components

HEADERS += \
    artworkcache.h \
    plugin.h \
    qrcodeitem.h \
    qrencoder.h \
    wifiqrcode.h

SOURCES += \
    artworkcache.cpp \
    plugin.cpp \
    qrcodeitem.cpp \
    qrencoder.cpp \
    wifiqrcode.cpp

# QrCode draws with libqrencode. The recipe always has it (DEPENDS qrencode);
# a desktop build for running app tests can do without, and QrCode is then
# never valid (error "unavailable") while WifiQrCode works as ever.
CONFIG += link_pkgconfig
packagesExist(libqrencode) {
    PKGCONFIG += libqrencode
    DEFINES += HAVE_QRENCODE
} else {
    warning("libqrencode not found: QrCode will draw nothing")
}

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath
INSTALLS += target
