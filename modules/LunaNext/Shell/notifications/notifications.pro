TEMPLATE = lib
TARGET = lunanext-shell-notifications-qml

QT += qml quick sql
CONFIG += qt plugin

CONFIG += link_pkgconfig
PKGCONFIG += luna-service2 luna-service2++ LunaSysMgrCommon

TARGET = $$qtLibraryTarget($$TARGET)
uri = LunaNext.Shell.Notifications

HEADERS += \
    plugin.h \
    qobjectlistmodel.h \
    categorydefinitionstore.h \
    notification.h \
    notificationmanager.h \
    notificationmanagerwrapper.h \
    notificationlistmodel.h

SOURCES += \
    plugin.cpp \
    qobjectlistmodel.cpp \
    categorydefinitionstore.cpp \
    notification.cpp \
    notificationmanager.cpp \
    notificationmanagerwrapper.cpp \
    notificationlistmodel.cpp

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)
target.path = $$installPath

qmldir_file.path = $$installPath
qmldir_file.files = qmldir

INSTALLS += target qmldir_file
