import QtQuick 2.9
import QtQuick.Controls 2.2

ApplicationWindow {
    id: appWindow

    enum Type {
        Card,
        Launcher,
        Dashboard,
        PopupAlert,
        BannerAlert,
        Overlay,
        Pin,
    }
    function windowTypeToString(type)
    {
        switch (type) {
        case LuneOSWindow.Card: return "card";
        case LuneOSWindow.Dashboard: return "dashboard";
        case LuneOSWindow.PopupAlert: return "popupalert";
        case LuneOSWindow.Pin: return "pin";
        }

        return "card";
    }

    property int type: LuneOSWindow.Card
    property readonly int windowId: 0
    property int parentWindowId: 0
    property bool keepAlive: false
    property bool loadingAnimationDisabled: false

    WindowPropertiesHelper {
        id: windowPropertiesHelper
        window: appWindow

        windowPropertyChanged: {
            if (propertyName === "_LUNE_WINDOW_ID") {
                appWindow.windowId = propertyValue;
            }
        }
    }

    onVisibleChanged: {
        if(visible) {
            // set different information bits for our window
            windowPropertiesHelper.setWindowProperty("_LUNE_WINDOW_TYPE", windowTypeToString(type));
            windowPropertiesHelper.setWindowProperty("_LUNE_WINDOW_LOADING_ANIMATION_DISABLED", mLoadingAnimationDisabled);
            windowPropertiesHelper.setWindowProperty("_LUNE_WINDOW_PARENT_ID", parentWindowId);
            windowPropertiesHelper.setWindowProperty("_LUNE_APP_ID", QCoreApplication::applicationName());
            windowPropertiesHelper.setWindowProperty("_LUNE_APP_KEEP_ALIVE", keepAlive);
        }
    }

}
