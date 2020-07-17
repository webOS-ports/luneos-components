import QtQuick 2.0

ListModel {
    id: ofonoSimListModel

    property bool requireSubscriberIdentity: true
    property bool valid: true

    signal simAdded
    signal simRemoved

    ListElement {
     path: "ril_0";
     subscriberIdentity: "identity1";
     mobileCountryCode: 354;
     mobileNetworkCode: 208;
     serviceProviderName: "Lycamobile FR";
     pinRequired: false;
     lockedPins: 0;
     cardIdentifier: "225586248552005881";
     attributes: [
         ListElement { subscriberNumbers: "985648524"},
         ListElement { serviceNumbers: "123"},
         ListElement { serviceNumbers: "666"},
         ListElement { preferredLanguages: "en"},
         ListElement { preferredLanguages: "nl"}
     ]
     pinRetries: 3;
     fixedDialing: false;
     barredDialing: false;
    }
    ListElement {
     path: "ril_1";
     subscriberIdentity: "identity2";
     mobileCountryCode: 354;
     mobileNetworkCode: 208;
     serviceProviderName: "Lycamobile NL";
     pinRequired: false;
     lockedPins: 0;
     cardIdentifier: "225586248552005881";
     attributes: [
         ListElement { subscriberNumbers: "985648524"},
         ListElement { serviceNumbers: "123"},
         ListElement { serviceNumbers: "666"},
         ListElement { preferredLanguages: "en"},
         ListElement { preferredLanguages: "nl"}
     ]
     pinRetries: 3;
     fixedDialing: false;
     barredDialing: false;
    }
}
