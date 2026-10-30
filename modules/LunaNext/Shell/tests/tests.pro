# Unit tests for LunaNext.Shell's C++: where ScreenShooter writes a
# screenshot (screenshooter.cpp). See README.md.
#
# Not part of the module's build; build it on its own:
#   qmake tests.pro && make
# It needs googletest in the sysroot (DEPENDS += "googletest").

TEMPLATE = app
TARGET = lunanext-shell-tests
CONFIG += console c++17
CONFIG -= app_bundle
QT = core gui qml quick

INCLUDEPATH += ..

HEADERS += ../screenshooter.h

SOURCES += \
    unit/main.cpp \
    unit/test_screenshooter.cpp \
    ../screenshooter.cpp

LIBS += -lgtest -lpthread

# Off by default; e.g. qmake "CONFIG+=sanitize" for ASan + UBSan.
sanitize {
    QMAKE_CXXFLAGS += -fsanitize=address,undefined -fno-omit-frame-pointer
    QMAKE_LFLAGS += -fsanitize=address,undefined
}
