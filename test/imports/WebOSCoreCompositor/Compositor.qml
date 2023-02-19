import QtQuick 2.12
import QtQml.Models 2.1

import Eos.Window 0.1

QtObject {
    id: compositorRoot

    property ListModel surfaceModel: ListModel {}
    property Component windowComp: WebOSWindow {}

    signal surfaceMapped(variant window);
    signal surfaceUnmapped(variant window);

    function createFakeWindow(windowKind, jsonArgs)
    {
        let newWindow = windowComp.createObject(compositorRoot, { title: windowKind, appId: jsonArgs.id });
        surfaceModel.append({ obj: newWindow });
        surfaceMapped(newWindow);
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
