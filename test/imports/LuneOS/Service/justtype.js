/*
 * Mock data for com.palm.universalsearch, which SearchPreferencesPage.qml
 * calls "Just Type" after the legacy app of the same name. Nothing on a
 * real LuneOS device implements this service yet (see that page's own
 * comment), so this mock is the only place it has ever answered - the
 * search/action/content item data below was recovered from the legacy
 * webOS TouchPad's own getUniversalSearchList response.
 *
 * Like wan.js/vpn.js/print.js, this is a .pragma library so LunaService.qml
 * instances share one item list and one set of preferences.
 */
.pragma library

// The service writes these as the strings "true"/"false", not as booleans -
// SearchPreferencesPage.qml's own _asBool() comment says it always has.
var preferences = {
    "AppSearch": "true",
    "ContactSearch": "true",
    "GAL": "false",
    "defaultSearch": "true",
    "defaultSearchEngine": "google"
};

var searchItems = [
    { "id": "google", "displayName": "Google",
      "iconFilePath": "/usr/palm/applications/com.palm.launcher/images/search-icon-google.png",
      "url": "https://www.google.com/search?q=#{searchTerms}",
      "suggestURL": "https://encrypted.google.com/complete/search?hl=en&output=firefox&q=#{searchTerms}",
      "launchParam": "", "type": "web", "enabled": true },
    { "id": "wikipedia", "displayName": "Wikipedia",
      "iconFilePath": "/usr/palm/applications/com.palm.launcher/images/search-icon-wikipedia.png",
      "url": "https://en.wikipedia.org/wiki/Special:Search?search=#{searchTerms}",
      "suggestURL": "https://en.wikipedia.org/w/api.php?action=opensearch&search=#{searchTerms}&limit=8&namespace=0&format=json",
      "launchParam": "", "type": "web", "enabled": true },
    { "id": "duckduckgo", "displayName": "DuckDuckGo",
      "iconFilePath": "/usr/palm/applications/com.palm.launcher/images/search-icon-duckduckgo.png",
      "url": "https://www.duckduckgo.com/?q=#{searchTerms}",
      "suggestURL": "", "launchParam": "", "type": "web", "enabled": true },
    { "id": "cnn", "displayName": "CNN",
      "iconFilePath": "/usr/palm/applications/com.palm.launcher/images/search-icon-cnn.png",
      "url": "http://www.cnn.com/search/?query=#{searchTerms}",
      "suggestURL": "", "launchParam": "", "type": "web", "enabled": false },
    { "id": "amazon", "displayName": "Amazon",
      "iconFilePath": "/usr/palm/applications/com.palm.launcher/images/search-icon-amazon.png",
      "url": "https://www.amazon.com/s/?k=#{searchTerms}",
      "suggestURL": "", "launchParam": "", "type": "web", "enabled": false },
    { "id": "imdb", "displayName": "IMDb",
      "iconFilePath": "/usr/palm/applications/com.palm.launcher/images/search-icon-imdb.png",
      "url": "http://www.imdb.com/find?q=#{searchTerms}",
      "suggestURL": "", "launchParam": "", "type": "web", "enabled": false }
];

var actionItems = [
    { "id": "com.palm.app.email", "displayName": "New Email",
      "iconFilePath": "/usr/palm/applications/com.palm.app.email/icon.png",
      "url": "com.palm.app.email", "launchParam": "text", "enabled": true },
    { "id": "com.palm.app.calendar", "displayName": "New Event",
      "iconFilePath": "/usr/palm/applications/com.palm.app.calendar/images/icon-256x256.png",
      "url": "com.palm.app.calendar", "launchParam": "quickLaunchText", "enabled": true },
    { "id": "org.webosports.app.messaging", "displayName": "New Message",
      "iconFilePath": "/usr/palm/applications/org.webosports.app.messaging/icon.png",
      "url": "org.webosports.app.messaging",
      "launchParam": "{ \"compose\": { \"messageText\": \"#{searchTerms}\" } }", "enabled": true }
];

var contentItems = [
    { "id": "com.palm.app.email", "displayName": "Email",
      "iconFilePath": "/usr/palm/applications/com.palm.app.email/icon.png",
      "launchParam": "emailId", "launchParamDbField": "_id",
      "dbQuery": { "from": "com.palm.email:1",
                   "where": [ { "prop": "flags.visible", "op": "=", "val": true },
                              { "prop": "searchText", "op": "?", "val": "", "collate": "primary" } ],
                   "orderBy": "timestamp", "desc": true, "limit": 20 },
      "displayFields": [ "from.name", "subject" ], "batchQuery": false, "enabled": true },
    { "id": "com.palm.app.calendar", "displayName": "Calendar Events",
      "iconFilePath": "/usr/palm/applications/com.palm.app.calendar/images/icon-256x256.png",
      "launchParam": "showEventDetail", "launchParamDbField": "_id",
      "dbQuery": { "from": "com.palm.calendarevent:1",
                   "where": [ { "prop": "searchText", "op": "?", "val": "", "collate": "primary" } ],
                   "orderBy": "subject", "desc": false, "limit": 20 },
      "displayFields": [ "subject", { "name": "dtstart", "type": "timestamp" } ],
      "batchQuery": false, "enabled": true }
];

var searchListSubscribers = [];

function preferencesPayload() {
    return { "returnValue": true, "SearchPreference": preferences };
}

function searchListPayload() {
    return { "returnValue": true, "subscribed": true,
             "UniversalSearchList": searchItems, "DBSearchItemList": contentItems,
             "ActionList": actionItems, "defaultSearchEngine": preferences.defaultSearchEngine };
}

function postSearchList() {
    var payload = { "payload": JSON.stringify(searchListPayload()) };
    for (var i = 0; i < searchListSubscribers.length; i++)
        searchListSubscribers[i](payload);
}

function setSearchPreference(key, value) {
    preferences[key] = value ? "true" : "false";
    return { "returnValue": true };
}

function _itemsForCategory(category) {
    if (category === "dbsearch")
        return contentItems;
    if (category === "action")
        return actionItems;
    return searchItems;
}

function updateSearchItem(id, enabled, category, setDefault) {
    var items = _itemsForCategory(category);
    var found = false;
    for (var i = 0; i < items.length; i++) {
        if (items[i].id === id) {
            items[i].enabled = enabled;
            found = true;
        }
    }
    if (!found)
        return { "returnValue": false, "errorCode": -1, "errorText": "Unknown item." };

    if (setDefault)
        preferences.defaultSearchEngine = id;

    postSearchList();
    return { "returnValue": true };
}

function updateAllSearchItems(category, enabled) {
    var items = _itemsForCategory(category);
    for (var i = 0; i < items.length; i++)
        items[i].enabled = enabled;
    postSearchList();
    return { "returnValue": true };
}
