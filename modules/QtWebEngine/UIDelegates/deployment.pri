installPath = $$[QT_INSTALL_QML]/LunaWebEngineViewStyle/QtWebEngine/UIDelegates

QML_FILES = \
    AlertDialog.qml \
    AuthenticationDialog.qml \
    ConfirmDialog.qml \
    FilePicker.qml \
    Menu.qml \
    MenuItem.qml \
    MenuSeparator.qml \
    MessageBubble.qml \
    PromptDialog.qml
IMAGE_FILES = images/popup-bg.png

OTHER_FILES += $$QML_FILES $$IMAGE_FILES

qml_files.path = $$installPath
qml_files.files = $$QML_FILES
images_files.path = $$installPath/images
images_files.files = $$IMAGE_FILES

INSTALLS += qml_files images_files
