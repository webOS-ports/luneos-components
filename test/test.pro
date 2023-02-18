TEMPLATE = aux

QML_FILES = $$files(*.qml, true)
JS_FILES = $$files(*.js, true)
IMAGES_FILES = $$files(*.png, true)
QMLDIR_FILE = $$files(qmldir, true)

OTHER_FILES += $$QML_FILES $$JS_FILES $$IMAGES_FILES $$QMLDIR_FILE

DISTFILES += \
    imports/WebOSCompositorBase/Compositor.qml \
    imports/WebOSCompositorBase/qmldir

