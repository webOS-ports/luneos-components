/*
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0

import "VoiceCallStatusStub.js" as VoiceCall;

Item {
    property string handlerId: "(handler)"
    property string providerId: "(provider)"
    property int status: VoiceCall.STATUS_NULL
    property string statusText: _getStatusText(status);
    property string lineId: "(line)"
    property date startedAt: new Date();
    property int duration: 0
    property bool isIncoming: false
    property bool isEmergency: false
    property bool isMultiparty: false
    property bool isForwarded: false
    property bool isReady: false
    property bool isRemoteHeld: false

    signal error(string error);

    Timer {
        interval: 1000; repeat: true; running: status === VoiceCall.STATUS_ACTIVE
        onTriggered: duration+=1000
    }

    function answer()
    {
        console.log("VoiceCall -> answer()");
        if( status === VoiceCall.STATUS_INCOMING )
            status = VoiceCall.STATUS_ACTIVE;
        duration = 0;
    }
    function hangup()
    {
        console.log("VoiceCall -> hangup()");
        if( status !== VoiceCall.STATUS_NULL && status !== VoiceCall.STATUS_DISCONNECTED )
            status = VoiceCall.STATUS_DISCONNECTED;
    }
    function hold(isOn)
    {
        console.log("VoiceCall -> hold("+isOn+")");
    }
    function deflect(target)
    {
        console.log("VoiceCall -> deflect("+target+")");
    }
    function sendDtmf(tones)
    {
        console.log("VoiceCall -> answer("+tones+")");
    }

    // Test behavior for the voice calls
    function _getStatusText(_status)
    {
        if(_status === VoiceCall.STATUS_ACTIVE) return "(ACTIVE)"
        if(_status === VoiceCall.STATUS_ALERTING) return "(ALERTING)"
        if(_status === VoiceCall.STATUS_DIALING) return "(DIALING)"
        if(_status === VoiceCall.STATUS_DISCONNECTED) return "(DISCONNECTED)"
        if(_status === VoiceCall.STATUS_HELD) return "(HELD)"
        if(_status === VoiceCall.STATUS_INCOMING) return "(INCOMING)"
        if(_status === VoiceCall.STATUS_NULL) return "(NULL)"
        if(_status === VoiceCall.STATUS_WAITING) return "(WAITING)"
        return "(status unknown)";
    }
    // Let it ring for 3s, then set the status as Active
    Timer {
        interval: 3000; repeat: false;
        running: status === VoiceCall.STATUS_DIALING
        onTriggered: status = VoiceCall.STATUS_ACTIVE
    }
    // Let the disconnect phase take 2s
    Timer {
        interval: 2000; repeat: false;
        running: status === VoiceCall.STATUS_DISCONNECTED
        onTriggered: status = VoiceCall.STATUS_NULL
    }
}
