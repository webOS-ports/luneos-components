import QtQuick 2.12
import QtQml.Models 2.1

import Eos.Window 0.1

// Item (not QtObject): createFakeWindow() below parents freshly-created
// visual windows onto this root via createObject(compositorRoot, ...).
// A QtObject has no place in the Qt Quick scene graph, so those windows
// were being created "outside" the graphics scene (QML would warn
// "Created graphical object was not placed in the graphics scene");
// they only ever became visible once CardView's own delegate machinery
// reparented them into the real visual tree moments later. Item fixes
// that at the source without depending on that reparenting timing.
Item {
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
