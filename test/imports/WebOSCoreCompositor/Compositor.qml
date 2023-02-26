import QtQuick 2.12
import QtQml.Models 2.1

import Eos.Window 0.1

QtObject {
    id: compositorRoot

    property ListModel surfaceModel: ListModel {}

    signal surfaceMapped(variant window);
    signal surfaceUnmapped(variant window);

    function createFakeWindow(windowKind, jsonArgs)
    {
        console.log("createFakeWindow: Creating " + windowKind + " window");
        let windowComp = Qt.createComponent("FakeWindows/" + windowKind + ".qml");

        if (windowComp.status === Component.Ready) {
            let newWindow = windowComp.createObject(compositorRoot, { compositor: compositorRoot, title: windowKind, appId: jsonArgs.id });
            surfaceModel.append({ obj: newWindow });
            surfaceMapped(newWindow);

            newWindow.Component.onDestruction.connect(() => { closeWindow(newWindow); });
        } else if (windowComp.status === Component.Error) {
            // Error Handling
            console.log("TestCompositor: Error loading component: ", windowComp.errorString());
        }
    }

    function closeWindow(window)
    {
        for(var i=0; i<surfaceModel.count; ++i) {
            if(surfaceModel.get(i).obj === window) {
                surfaceModel.remove(i);
                surfaceUnmapped(window);

                window.destroy();
            }
        }
    }
}
