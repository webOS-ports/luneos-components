TEMPLATE = lib
CONFIG += plugin
TARGET = luneos-camera-qml

uri = LuneOS.Camera

# multimedia-private is what puts QtMultimedia/spi/qgstreamervideosource.h on
# the include path. It only exists when qtmultimedia was built with
# -DFEATURE_gstreamer_qt_api=ON (see the qtmultimedia bbappend); without it
# droidcamerafactory.cpp compiles to a stub via __has_include and reports
# available == false, so the module still builds and imports cleanly.
QT += qml quick multimedia multimedia-private

CONFIG += link_pkgconfig
PKGCONFIG += gstreamer-1.0

SOURCES += \
    plugin.cpp \
    droidcamerafactory.cpp

HEADERS += \
    droidcamerafactory.h

OTHER_FILES += qmldir

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

target.path = $$installPath

qmldir_file.path = $$installPath
qmldir_file.files = qmldir

INSTALLS += target qmldir_file
