import QtQuick 2.0

Item {
    property string modemPath: ""
    property string state: ready ? "online" : "offline"
    property bool ready: (modemPath !== "")

    // A '*100#'-style balance code answers straight away; anything else opens a
    // menu, so the interactive USSD path can be exercised on the desktop.
    function initiate(command) {
        if(!ready) {
            initiateFailed();
            return;
        }

        console.log("Initiating USSD "+command);

        if(command.indexOf("*100") === 0) {
            state = "idle";
            ussdResponse("Your balance is EUR 12.34.");
        }
        else {
            state = "user-response";
            requestReceived("Mock menu for " + command + "\n1. Balance\n2. Top up\n3. Bundles");
        }
    }

    function respond(reply) {
        state = "idle";
        respondComplete(true, "Thanks, you chose " + reply + ".");
        ussdResponse("Thanks, you chose " + reply + ".");
    }

    function cancel() {
        state = "idle";
        cancelComplete(true);
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
