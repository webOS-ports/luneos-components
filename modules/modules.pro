TEMPLATE = subdirs

SUBDIRS += \
    QtQuick/Controls/Styles/LuneOS/styles.pro \
    LuneOS/Components/components.pro \
    LuneOS/Application/application.pro \

!CONFIG(desktop) {
    SUBDIRS += LuneOS/Service/service.pro
}
