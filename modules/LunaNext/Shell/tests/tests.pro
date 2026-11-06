# Unit tests for LunaNext.Shell's C++: where ScreenShooter writes a
# screenshot (screenshooter.cpp), and the touch events InverseMouseArea maps
# (inversemouseareatype.cpp), the frames FpsCounter counts (fpscounter.cpp),
# ReticleItem's properties (reticleitem.cpp),
# and the notifications' store, list model and
# manager (notifications/). See README.md.
#
# Not part of the module's build; build it on its own:
#   qmake tests.pro && make
# It needs googletest in the sysroot (DEPENDS += "googletest").

TEMPLATE = app
TARGET = lunanext-shell-tests
CONFIG += console c++17
CONFIG -= app_bundle
QT = core gui qml quick quick-private sql testlib

INCLUDEPATH += ..

HEADERS += ../screenshooter.h ../inversemouseareatype.h ../quickutils.h ../fpscounter.h ../reticleitem.h \
    ../notifications/categorydefinitionstore.h \
    ../notifications/notification.h \
    ../notifications/notificationmanager.h \
    ../notifications/qobjectlistmodel.h

SOURCES += \
    unit/main.cpp \
    unit/test_screenshooter.cpp \
    unit/test_inversemousearea.cpp \
    unit/test_notifications.cpp \
    unit/test_fpscounter.cpp \
    unit/test_reticleitem.cpp \
    ../screenshooter.cpp \
    ../inversemouseareatype.cpp \
    ../quickutils.cpp \
    ../fpscounter.cpp \
    ../reticleitem.cpp \
    ../notifications/categorydefinitionstore.cpp \
    ../notifications/notification.cpp \
    ../notifications/notificationmanager.cpp \
    ../notifications/qobjectlistmodel.cpp

CONFIG += link_pkgconfig
PKGCONFIG += LunaSysMgrCommon glib-2.0

LIBS += -lgtest -lpthread

# Off by default; e.g. qmake "CONFIG+=sanitize" for ASan + UBSan.
sanitize {
    QMAKE_CXXFLAGS += -fsanitize=address,undefined -fno-omit-frame-pointer
    QMAKE_LFLAGS += -fsanitize=address,undefined
}
