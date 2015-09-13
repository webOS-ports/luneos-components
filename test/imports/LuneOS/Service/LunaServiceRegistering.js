.pragma library

var _listRegisteredMethods = new Array;
var _listLaunchPoints = [
            { "title": "Calendar", "id": "com.palm.app.calendar", "icon": "../images/default-app-icon.png", "removable": true },
            { "title": "Email", "id": "com.palm.app.email", "icon": "../images/default-app-icon.png", "userHideable": false },
            { "title": "Calculator", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png", "showInSearch": false },
            { "title": "Snowshoe", "id": "com.palm.app.browser", "icon": "../images/default-app-icon.png", "userHideable": true },
            { "title": "This is a long title", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "This_is_also_a_long_title", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Preware 5", "id": "com.palm.app.swmanager", "icon": "../images/default-app-icon.png" },
            { "title": "iOS", "id": "com.palm.app.screenlock", "icon": "../images/default-app-icon.png" },
            { "title": "Oh My", "id": "com.palm.app.enyo-findapps", "icon": "../images/default-app-icon.png" },
            { "title": "Test1", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "DummyWindow", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "DummyWindow2", "id": "org.webosports.tests.dummyWindow2", "icon": "../images/default-app-icon.png" },
            { "title": "DashboardWindow", "id": "org.webosports.tests.fakeDashboardWindow", "icon": "../images/default-app-icon.png" },
            { "title": "SIMPinWindow", "id": "org.webosports.tests.fakeSimPinWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Oh My", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test No Tab", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test3", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test5", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test5bis", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "Test6", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
            { "title": "End Of All Tests", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" }
        ];

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
