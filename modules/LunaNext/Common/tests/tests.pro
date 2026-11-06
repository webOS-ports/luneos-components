# Unit tests for LunaNext.Common's C++: the sizes Units gives and the
# uiScale it takes (units.cpp), and the panel shape SettingsAdapter reads
# (settingsadapter.cpp). See README.md.
#
# Not part of the module's build; build it on its own:
#   qmake tests.pro && make
# It needs googletest in the sysroot (DEPENDS += "googletest").

TEMPLATE = app
TARGET = lunanext-common-tests
CONFIG += console c++17
CONFIG -= app_bundle
QT = core gui qml

INCLUDEPATH += ..

HEADERS += ../units.h ../settingsadapter.h

SOURCES += \
    unit/main.cpp \
    unit/test_units.cpp \
    unit/test_settingsadapter.cpp \
    ../units.cpp \
    ../settingsadapter.cpp

CONFIG += link_pkgconfig
PKGCONFIG += LunaSysMgrCommon glib-2.0

LIBS += -lgtest -lpthread

# Off by default; e.g. qmake "CONFIG+=sanitize" for ASan + UBSan.
sanitize {
    QMAKE_CXXFLAGS += -fsanitize=address,undefined -fno-omit-frame-pointer
    QMAKE_LFLAGS += -fsanitize=address,undefined
}
