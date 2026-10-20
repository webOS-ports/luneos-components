import QtQuick 2.0

/*
 * Stand-in for WebOSCoreCompositor's KeyFilter (WebOSKeyFilter). The real one
 * calls each registered function for every key the compositor sees; here they
 * are only collected, so a test can see what was registered and call it itself.
 */
QtObject {
    property var filters: ({})

    function addKeyFilter(func, name) {
        filters[name] = func;
    }
}
