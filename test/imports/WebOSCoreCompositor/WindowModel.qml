import QtQuick 2.0

import "Singletons"

ListModel {
    id: windowModel

    property ListModel surfaceSource
    property string windowType: "_WEBOS_WINDOW_TYPE_CARD"

    property ListModel _referenceModel

    signal rowsAboutToBeInserted(variant index, int first, int last)
    signal rowsAboutToBeRemoved(variant index, int first, int last)
    signal rowsInserted(variant index, int first, int last)
    signal rowsRemoved(variant index, int first, int last)
    signal dataChanged(variant topLeft, variant bottomRight, variant roles)

    function get(index) {
        return _referenceModel.get(index);
    }

    function getByIndex(i) {
        if( i<0 || i>=_referenceModel.count ) {
            console.log("index "+ i +" out of range !");
        }

        return get(i).window;
    }

    onRowsInserted: {
        windowModel.append( _referenceModel.get(last) );
    }
    onRowsRemoved: {
        windowModel.remove( last );
    }

    Component.onCompleted: {
        if( windowTypeFilter === "_WEBOS_WINDOW_TYPE_CARD" )
            _referenceModel = WindowModelSingleton.cardListModel;

        // windowModel.count = Qt.binding(function() { return _referenceModel.count });
        _referenceModel.rowsAboutToBeInserted.connect(rowsAboutToBeInserted);
        _referenceModel.actualRowsAboutToBeRemoved.connect(rowsAboutToBeRemoved);
        _referenceModel.actualRowsInserted.connect(rowsInserted);
        _referenceModel.rowsRemoved.connect(rowsRemoved);
        _referenceModel.dataChanged.connect(dataChanged);
        // _referenceModel.countChanged.connect(updateCount);
    }
}
