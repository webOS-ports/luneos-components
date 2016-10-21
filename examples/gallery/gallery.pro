TEMPLATE = subdirs

QT += qml quick quickcontrols2

OTHER_FILES += \
    appinfo.json \
    gallery.qml \
    pages/*.qml

files.path = /usr/palm/applications/org.luneos.components.gallery
files.files += $$OTHER_FILES

INSTALLS += files
