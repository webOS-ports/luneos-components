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
    luneosmenu.h \
    luneosmenuattachedtype.h \
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
    luneosmenu.cpp \
    luneosmenuattachedtype.cpp \
    luneosbutton.cpp \
    luneosbuttonattachedtype.cpp \
    luneosswipedelegate.cpp \
    luneosswipedelegateattachedtype.cpp

installPath = $$[QT_INSTALL_QML]/QtQuick/Controls/LuneOS
target.path = $$installPath

INSTALLS += target qmldir_file qml_files js_files
