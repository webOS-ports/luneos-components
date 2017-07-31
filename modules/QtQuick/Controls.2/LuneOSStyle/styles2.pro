TEMPLATE = subdirs

SUBDIRS += plugin

QML_FILES = \
    ApplicationWindow.qml \
    BusyIndicator.qml \
    Button.qml \
    CheckBox.qml \
    CheckDelegate.qml \
    CheckIndicatorLuneOS.qml \
    ComboBox.qml \
    Dial.qml \
    Drawer.qml \
    Frame.qml \
    GroupBox.qml \
    ItemDelegate.qml \
    Label.qml \
    MenuItem.qml \
    Menu.qml \
    PageIndicator.qml \
    Page.qml \
    Pane.qml \
    Popup.qml \
    ProgressBar.qml \
    RadioButton.qml \
    RadioDelegate.qml \
    RadioIndicatorLuneOS.qml \
    RangeSlider.qml \
    ScrollBar.qml \
    ScrollIndicatorLuneOS.qml \
    Slider.qml \
    SpinBox.qml \
    StackView.qml \
    SwipeDelegate.qml \
    SwipeView.qml \
    SwitchDelegate.qml \
    SwitchIndicatorLuneOS.qml \
    Switch.qml \
    TabBar.qml \
    TabButton.qml \
    TextArea.qml \
    TextField.qml \
    ToolBar.qml \
    ToolButton.qml \
    ToolTip.qml \
    Tumbler.qml

JS_FILES =
QMLDIR_FILE = qmldir

OTHER_FILES += $$QML_FILES $$JS_FILES $$QMLDIR_FILE

installPath = $$[QT_INSTALL_QML]/QtQuick/Controls.2/LuneOS

other_files.path = $$installPath
other_files.files = qmldir *.qml *.js

images_files.path = $$installPath/images
images_files.files = images/*.png images/*.gif images/*.jpg

INSTALLS += other_files images_files
