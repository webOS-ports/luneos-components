pragma Singleton
import QtQuick 2.0

import WebOSServices 1.0

/*
 * Stand-in for WebOSCompositorBase's LS (global/LS.qml), the bus handles the
 * surface manager shares. luna-next-cardshell uses three of them: appId,
 * adhoc for one-off calls, and applicationManager, whose app life events
 * CardView follows. Nothing here talks to a bus; a test drives
 * applicationManager.appLifeEventsChanged() itself.
 */
QtObject {
    id: root

    readonly property string appId: "com.webos.surfacemanager"

    readonly property Service adhoc: Service {
        appId: root.appId
    }

    readonly property QtObject applicationManager: QtObject {
        property string appId: root.appId
        property bool connected: true

        signal appLifeEventsChanged(string appId, string event)
    }
}
