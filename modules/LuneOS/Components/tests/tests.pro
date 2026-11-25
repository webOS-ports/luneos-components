# Unit tests for LuneOS.Components' C++: the artwork cache behind
# image://artwork and ArtworkImage (plugin/artworkcache.cpp), and QrCode and
# WifiQrCode (plugin/qrencoder.cpp, qrcodeitem.cpp, wifiqrcode.cpp). See
# README.md.
#
# Not part of the module's build; build it on its own:
#   qmake tests.pro && make
# It needs googletest, libqrencode and zbar (which reads the codes back).

TEMPLATE = app
TARGET = luneos-components-tests
CONFIG += console c++17
CONFIG -= app_bundle
QT = core gui svg quick testlib

INCLUDEPATH += ../plugin

HEADERS += \
    ../plugin/qrcodeitem.h \
    ../plugin/wifiqrcode.h

SOURCES += \
    unit/main.cpp \
    unit/test_artworkcache.cpp \
    unit/test_qrcode.cpp \
    unit/test_wifiqrcode.cpp \
    ../plugin/artworkcache.cpp \
    ../plugin/qrcodeitem.cpp \
    ../plugin/qrencoder.cpp \
    ../plugin/wifiqrcode.cpp

DEFINES += HAVE_QRENCODE
CONFIG += link_pkgconfig
PKGCONFIG += libqrencode zbar
LIBS += -lgtest -lpthread

# Off by default; e.g. qmake "CONFIG+=sanitize" for ASan + UBSan.
sanitize {
    QMAKE_CXXFLAGS += -fsanitize=address,undefined -fno-omit-frame-pointer
    QMAKE_LFLAGS += -fsanitize=address,undefined
}
