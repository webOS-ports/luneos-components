TEMPLATE = subdirs

SUBDIRS += \
    QtQuick/Controls/Styles/LuneOS/styles.pro \
    QtWebEngine/UIDelegates/webengineviewdelegates.pro \
    LuneOS/Components/components.pro \
    LuneOS/Application/application.pro \
    LuneOS/Telephony/telephony.pro \


win32|mac {
    CONFIG += desktop
}

!CONFIG(desktop) {
    SUBDIRS += LuneOS/Service/service.pro
}
