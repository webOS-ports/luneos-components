TEMPLATE = subdirs

SUBDIRS += \
    QtQuick/Controls/Styles/LuneOS/styles.pro \
    QtQuick/Controls.2/LuneOS/styles2.pro \
    LuneOS/Components/components.pro \
    LuneOS/Telephony/telephony.pro \
    LunaNext/Common/common.pro \
    LunaNext/Shell/notifications/notifications.pro \
    LunaNext/Shell/shell.pro
    
qtHaveModule(BluezQt): SUBDIRS += LuneOS/Bluetooth/bluetooth.pro

win32|mac {
    CONFIG += desktop
}

!CONFIG(desktop) {
    SUBDIRS += LuneOS/Service/service.pro
}
