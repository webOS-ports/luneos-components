TEMPLATE = subdirs

QT += qml quick

OTHER_FILES += \
    appinfo.json \
    main.qml \
    ButtonPage.qml

files.path = /usr/palm/applications/org.luneos.components.gallery
files.files += $$OTHER_FILES

INSTALLS += files
