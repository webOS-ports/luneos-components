/*
 * Shared dual SIM state for the desktop LunaService stub.
 *
 * telephonyd is a single service, but each LunaService{} in QML is its own
 * mock object, and a connector typically creates one per method. Keeping the
 * state in a .pragma library means a defaultSimSet issued through one instance
 * is seen by the simListQuery subscription held by another, the way it works
 * against the real bus.
 */
.pragma library

// set to 1 to check that a single SIM device still looks the way it always did
var simCountMock = 2;

var sims = [
    {
        "simId": 0, "present": true, "name": "SIM 1",
        "iccid": "8931440000000000001", "imsi": "204040000000001",
        "msisdn": "+31600000001", "operatorName": "Vodafone",
        "simStatus": "simready", "powered": true, "ready": true, "bars": 4,
        "state": "service", "registration": "home",
        "networkRegistered": true, "dataRegistered": true
    },
    {
        "simId": 1, "present": true, "name": "SIM 2",
        "iccid": "8931440000000000002", "imsi": "204080000000002",
        "msisdn": "+31600000002", "operatorName": "KPN",
        "simStatus": "simready", "powered": true, "ready": true, "bars": 2,
        "state": "service", "registration": "roam",
        "networkRegistered": true, "dataRegistered": false
    },
    /*
     * Slots 3 and 4, for a phone with four (brax3). Not reported until
     * setSimCount() asks for them, so a run that does not is still dual SIM.
     */
    {
        "simId": 2, "present": true, "name": "SIM 3",
        "iccid": "8931440000000000003", "imsi": "204160000000003",
        "msisdn": "+31600000003", "operatorName": "Odido",
        "simStatus": "simready", "powered": true, "ready": true, "bars": 3,
        "state": "service", "registration": "home",
        "networkRegistered": true, "dataRegistered": false
    },
    {
        "simId": 3, "present": true, "name": "SIM 4",
        "iccid": "8931440000000000004", "imsi": "204200000000004",
        "msisdn": "+31600000004", "operatorName": "Lebara",
        "simStatus": "simready", "powered": true, "ready": true, "bars": 1,
        "state": "service", "registration": "home",
        "networkRegistered": true, "dataRegistered": false
    }
];

var defaultSim = { "voice": 0, "sms": 0, "data": 1 };

var simListSubscribers = [];
var defaultSimSubscribers = [];

function simById(simId) {
    for (var i = 0; i < simCountMock && i < sims.length; i++)
        if (sims[i].simId === simId)
            return sims[i];
    return null;
}

function simsPayload() {
    var out = [];
    for (var i = 0; i < simCountMock && i < sims.length; i++) {
        var sim = sims[i];
        out.push({
            "simId": sim.simId, "present": sim.present, "name": sim.name,
            "iccid": sim.iccid, "imsi": sim.imsi, "msisdn": sim.msisdn,
            "operatorName": sim.operatorName, "simStatus": sim.simStatus,
            "powered": sim.powered, "ready": sim.ready, "bars": sim.bars,
            "state": sim.state, "registration": sim.registration,
            "networkRegistered": sim.networkRegistered,
            "dataRegistered": sim.dataRegistered,
            "defaultForVoice": defaultSim.voice === sim.simId,
            "defaultForSms": defaultSim.sms === sim.simId,
            "defaultForData": defaultSim.data === sim.simId
        });
    }
    return {
        "returnValue": true, "subscribed": true,
        "simCount": out.length, "sims": out, "defaultSim": defaultSim
    };
}

function postSimList() {
    var payload = { "payload": JSON.stringify(simsPayload()) };
    for (var i = 0; i < simListSubscribers.length; i++)
        simListSubscribers[i](payload);

    var def = { "payload": JSON.stringify({
        "returnValue": true, "subscribed": true, "defaultSim": defaultSim }) };
    for (var j = 0; j < defaultSimSubscribers.length; j++)
        defaultSimSubscribers[j](def);
}

/*
 * How many slots the mock reports, 1 to sims.length, posted to every
 * simListQuery subscriber at once. For a test: assigning simCountMock from QML
 * is not a reliable way to change a .pragma library's state, and the test case
 * runs after the shell has already subscribed, so the new list has to be
 * posted. Reachable as DualSim.setSimCount() through "import LuneOS.Service 1.0".
 */
function setSimCount(count) {
    if (count < 1 || count > sims.length)
        return false;
    simCountMock = count;
    postSimList();
    return true;
}
