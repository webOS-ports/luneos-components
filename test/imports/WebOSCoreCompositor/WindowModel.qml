import QtQuick 2.0
import QtQml.Models 2.1

import "Singletons"

ObjectModel {
    id: windowModel

    property ListModel surfaceSource
    property string windowType: "NONE"
    property string acceptFunction;

    signal rowsAboutToBeInserted(variant index, int first, int last)
    signal rowsAboutToBeRemoved(variant index, int first, int last)
    signal rowsInserted(variant index, int first, int last)
    signal rowsRemoved(variant index, int first, int last)
    signal dataChanged(variant topLeft, variant bottomRight, variant roles)

    function getByIndex(index) {
        return windowModel.get(index);
    }

    property Connections cnx: Connections {
        target: surfaceSource

        function onRowsInserted(index, first, last) {
            let window = surfaceSource.get(last).obj;
            let filterAccept = false;

            // apply filter acceptFunction
            if(acceptFunction) {
                if (typeof windowModel[acceptFunction] == 'function') {
                    filterAccept = windowModel[acceptFunction](window);
                }
            }

            if(filterAccept ||
               window.type === windowModel.windowType) {
                let creationIndex = windowModel.count;
                windowModel.rowsAboutToBeInserted(null, creationIndex, creationIndex);
                windowModel.append(window);
                windowModel.rowsInserted(null, creationIndex, creationIndex);
            }
        }

        function onRowsAboutToBeRemoved(index, first, last) {
            let window = surfaceSource.get(last).obj;
            for(var i=0; i<windowModel.count; ++i) {
                if(windowModel.get(i) === window) {
                    windowModel.rowsAboutToBeRemoved(null, i, i);
                    windowModel.remove(i);
                    windowModel.rowsRemoved(null, i, i);
                    break;
                }
            }
        }
    }
}
