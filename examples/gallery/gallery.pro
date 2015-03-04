TEMPLATE = subdirs

QT += qml quick

OTHER_FILES += \
    appinfo.json \
    main.qml \
    content/ButtonPage.qml \
    content/SliderPage.qml \
    content/ProgressBarPage.qml \
    content/TabBarPage.qml \
    content/CheckBoxPage.qml \
    content/SplitViewPage.qml \
    content/TextInputPage.qml

files.path = /usr/palm/applications/org.luneos.components.gallery
files.files += $$OTHER_FILES

INSTALLS += files
