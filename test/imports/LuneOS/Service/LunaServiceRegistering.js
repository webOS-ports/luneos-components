.pragma library

var _listRegisteredMethods = new Array;
var _listLaunchPoints = [
            { "title": "Calendar", "id": "com.palm.app.calendar", "icon": "../images/default-app-icon.png", "removable": true },
            { "title": "Email", "id": "com.palm.app.email", "icon": "../images/default-app-icon.png", "userHideable": false },
            { "title": "Messaging", "id": "org.webosports.app.messaging", "icon": "../images/default-app-icon.png", "removable": true },
            { "title": "Memos", "id": "org.webosports.app.memos", "icon": "../images/default-app-icon.png", "userHideable": false },
            { "title": "Phone", "id": "org.webosports.app.phone", "icon": "../images/default-app-icon.png", "userHideable": false },
            { "title": "Calculator", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png", "showInSearch": false },
            { "title": "Browser", "id": "org.webosports.app.browser", "icon": "../images/default-app-icon.png", "userHideable": true },
            { "title": "This is a long title", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" },
            { "title": "This_is_also_a_long_title", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Preware 5", "id": "com.palm.app.swmanager", "icon": "../images/default-app-icon.png" },
            { "title": "iOS", "id": "com.palm.app.screenlock", "icon": "../images/default-app-icon.png" },
            { "title": "Oh My", "id": "com.palm.app.enyo-findapps", "icon": "../images/default-app-icon.png" },
            { "title": "Test1", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" },
            { "title": "DummyWindow", "id": "org.webosports.tests.dummyWindow", "icon": "../Tests/images/test-app-icon.png" },
            { "title": "DummyWindow2", "id": "org.webosports.tests.dummyWindow2", "icon": "../Tests/images/test2-app-icon.png" },
            { "title": "DashboardWindow", "id": "org.webosports.tests.fakeDashboardWindow", "icon": "../Tests/images/dashboard-app-icon.png" },
            { "title": "PopupAlertWindow", "id": "org.webosports.tests.fakePopupAlertWindow", "icon": "../Tests/images/alert-app-icon.png" },
            { "title": "SIMPinWindow", "id": "org.webosports.tests.fakeSimPinWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Oh My", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test No Tab", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test3", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test5", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test5bis", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test6", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" },
            { "title": "End Of All Tests", "id": "org.webosports.tests.noWindow", "icon": "../images/default-app-icon.png" }
        ];
_listLaunchPoints.forEach((elt) => {
    // initialize missing properties
    if(typeof elt.removable === 'undefined') elt.removable = false;
    if(typeof elt.launchPointId === 'undefined') elt.launchPointId = elt.id;
    if(typeof elt.appId === 'undefined') elt.appId = elt.id;
});

function addRegisteredMethod(name, fct) {
    _listRegisteredMethods.push({"name": name, "fct": fct});
}

function executeMethod(name, args) {
    var index = 0;

    for (var n = _listRegisteredMethods.length-1; n >= 0; n--) {
        var methodItem = _listRegisteredMethods[n];
        if( methodItem.name === name ) {
            methodItem.fct(args);
            return true;
        }
    }

    return false;
}
