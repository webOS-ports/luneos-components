TEMPLATE = lib
TARGET = ../luneosstyleplugin

QT += qml quick
CONFIG += qt plugin

TARGET = $$qtLibraryTarget($$TARGET)

HEADERS += \
    plugin.h \
    luneosswitch.h \
    luneosswitchattachedtype.h \
    luneosradiobutton.h \
    luneosradiobuttonattachedtype.h \
    luneosbutton.h \
    luneosbuttonattachedtype.h \
    luneosswipedelegate.h \
    luneosswipedelegateattachedtype.h

SOURCES += \
    plugin.cpp \
    luneosswitch.cpp \
    luneosswitchattachedtype.cpp \
    luneosradiobutton.cpp \
    luneosradiobuttonattachedtype.cpp \
    luneosbutton.cpp \
    luneosbuttonattachedtype.cpp \
    luneosswipedelegate.cpp \
    luneosswipedelegateattachedtype.cpp

installPath = $$[QT_INSTALL_QML]/QtQuick/Controls.2/LuneOSStyle
target.path = $$installPath
INSTALLS += target
