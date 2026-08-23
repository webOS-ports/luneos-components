import QtQuick 2.0

Item {
    property string modemPath: ""
    property string state: ready ? "online" : "offline"
    property bool ready: (modemPath !== "")

    function initiate(command) {
        if(ready) {
            console.log("Initiating USSD "+command);
            ussdResponse("You sent: "+command);
        }
    }

    function respond() {
    }

    function cancel() {
    }

    signal notificationReceived(string message);
    signal requestReceived(string message);
    signal ussdResponse(string response);
    signal callBarringResponse(string ssOp, string cbService, variant cbMap);
    signal callForwardingResponse(string ssOp, string cfService, variant cfMap);
    signal callWaitingResponse(string ssOp, variant cwMap);
    signal callingLinePresentationResponse(string ssOp, string status);
    signal connectedLinePresentationResponse(string ssOp, string status);
    signal callingLineRestrictionResponse(string ssOp, string status);
    signal connectedLineRestrictionResponse(string ssOp, string status);
    signal initiateFailed();
    signal respondComplete(bool success, string message);
    signal cancelComplete(bool success);
}
