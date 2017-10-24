import QtQuick 2.0

Item {
    id: clockModel

    property string timezone: ""
    property string timezoneUpdates: ""
    property string timeUpdates: ""
    property variant /*QStringList*/ timeservers: []

}
