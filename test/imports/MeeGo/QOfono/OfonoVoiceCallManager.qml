import QtQuick 2.0

Item {
    id: voiceCallManager

    signal callRemoved
    signal callAdded

    property string modemPath

    function hangupAll() { }
    function dial(number) { }
}
