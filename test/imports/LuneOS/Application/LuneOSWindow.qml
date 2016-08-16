import QtQuick 2.1

Item {
    id: window

    property int type: 0
    property int parentWindowId: 0
    property bool loadingAnimationDisabled: false
    property bool keepAlive: false
    property int windowId: 0
    property string color: "transparent"


    function show() {
        window.visible = true;
    }

    function hide() {
        window.visible = false;
    }
    function close() {
        hide();
        closed();
    }

    signal closed();
}
