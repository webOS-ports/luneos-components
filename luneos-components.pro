TEMPLATE = subdirs
SUBDIRS += modules examples

windows:mac {
    CONFIG+=desktop
}
