# Unit tests for LuneOS.Components' C++: the artwork cache behind
# image://artwork and ArtworkImage (plugin/artworkcache.cpp). See README.md.
#
# Not part of the module's build; build it on its own:
#   qmake tests.pro && make
# It needs googletest in the sysroot (DEPENDS += "googletest").

TEMPLATE = app
TARGET = luneos-components-tests
CONFIG += console c++17
CONFIG -= app_bundle
QT = core gui svg

INCLUDEPATH += ../plugin

SOURCES += \
    unit/main.cpp \
    unit/test_artworkcache.cpp \
    ../plugin/artworkcache.cpp

LIBS += -lgtest -lpthread

# Off by default; e.g. qmake "CONFIG+=sanitize" for ASan + UBSan.
sanitize {
    QMAKE_CXXFLAGS += -fsanitize=address,undefined -fno-omit-frame-pointer
    QMAKE_LFLAGS += -fsanitize=address,undefined
}
