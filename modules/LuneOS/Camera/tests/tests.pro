# Unit tests for the parts of LuneOS.Camera that need no camera: the control
# tables and arithmetic (cameracontrols.cpp), the barcode frame handling and
# decoding (barcodedecoder.cpp), the threaded scanner around it
# (barcodescanner.cpp) and the camera's wrapper bin (droidcamerabin.cpp,
# with GStreamer's core elements). See README.md.
#
# Not part of the module's build; build it on its own:
#   qmake tests.pro && make
# It needs googletest in the sysroot (DEPENDS += "googletest").

TEMPLATE = app
TARGET = luneos-camera-tests
CONFIG += console c++17
CONFIG -= app_bundle
QT = core gui multimedia

CONFIG += link_pkgconfig
PKGCONFIG += gstreamer-1.0 zbar
DEFINES += GST_USE_UNSTABLE_API

INCLUDEPATH += ..

SOURCES += \
    unit/main.cpp \
    unit/test_cameracontrols.cpp \
    unit/test_barcodedecoder.cpp \
    unit/test_barcodescanner.cpp \
    unit/test_droidcamerabin.cpp \
    ../cameracontrols.cpp \
    ../barcodedecoder.cpp \
    ../barcodescanner.cpp \
    ../droidcamerabin.cpp

HEADERS += \
    ../barcodescanner.h

LIBS += -lgtest -lpthread

# Off by default; e.g. qmake "CONFIG+=sanitize" for ASan + UBSan.
sanitize {
    QMAKE_CXXFLAGS += -fsanitize=address,undefined -fno-omit-frame-pointer
    QMAKE_LFLAGS += -fsanitize=address,undefined
}
