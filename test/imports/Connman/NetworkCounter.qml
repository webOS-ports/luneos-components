import QtQuick 2.9

Item {
    id: networkCounter

    property int bytesReceived: 0
    property int bytesTransmitted: 0
    property int secondsOnline: 0
    property bool roaming: false
    property int accuracy: 10
    property int interval: 1000

    property bool running: false

    signal counterChanged(string servicePath, variant counters, bool roaming);

    function updateCounterAgent() {
    }
}
