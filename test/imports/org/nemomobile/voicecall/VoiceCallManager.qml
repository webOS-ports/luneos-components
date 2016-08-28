/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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
import QtQml.Models 2.2

import "VoiceCallStatusStub.js" as VoiceCall;

Item {
    id: testVoiceCallMgr
    // oh boy, waiting for the ObjectModel improvements in Qt 5.6 !
    property ObjectModel voiceCalls: ObjectModel {
        id: _voiceCalls
        signal rowsInserted(int first, int last);
        VoiceCall {
            id: testVoiceCall1
            isIncoming: true
            onStatusChanged: {
                if(status===VoiceCall.STATUS_ACTIVE) activeVoiceCall = testVoiceCall1;
                else if(activeVoiceCall===testVoiceCall1) activeVoiceCall = null;
            }
        }
        VoiceCall {
            id: testVoiceCall2
            onStatusChanged: {
                if(status===VoiceCall.STATUS_ACTIVE) activeVoiceCall = testVoiceCall2;
                else if(activeVoiceCall===testVoiceCall2) activeVoiceCall = null;
            }
        }

        function instance(idx) {
            if(idx===1) return testVoiceCall1;
            if(idx===2) return testVoiceCall2;
            return null;
        }
        Component.onCompleted: rowsInserted(1,2);
    }
    property ListModel providers: ListModel {}

    property string defaultProviderId: "provider"

    property VoiceCall activeVoiceCall

    property string audioMode: "normal"
    property bool isAudioRouted: true
    property bool isMicrophoneMuted: false
    property bool isSpeakerMuted: false

    signal error(string message);

    signal defaultProviderChanged();

    signal audioRoutedChanged();
    signal microphoneMutedChanged();
    signal speakerMutedChanged();

    function dial(providerId, msisdn)
    {
        // hard-code some dial numbers to cover other UI functionalities
        if(msisdn==="111" || msisdn==="999") {
            testVoiceCall1.lineId = msisdn;
            if( testVoiceCall1.status === VoiceCall.STATUS_NULL )
                testVoiceCall1.status = VoiceCall.STATUS_INCOMING;
        }
        else
        {
            console.log("--> dial: providerId=" + providerId + " msisdn=" + msisdn);
            if( testVoiceCall2.status === VoiceCall.STATUS_NULL )
            {
                testVoiceCall2.providerId = providerId;
                testVoiceCall2.lineId = msisdn;
                testVoiceCall2.status = VoiceCall.STATUS_DIALING;
            }
        }
    }

    function silenceRingtone()
    {
        console.log("--> silenceRingtone");
    }

    function setAudioMode(mode)
    {
        console.log("--> setAudioMode mode="+mode);
    }
    function setAudioRouted(isOn)
    {
        console.log("--> setAudioRouted on="+isOn);
    }
    function setMuteMicrophone(isOn)
    {
        console.log("--> setMuteMicrophone on="+isOn);
    }
    function setMuteSpeaker(isOn)
    {
        console.log("--> setMuteSpeaker on="+isOn);
    }

    function startDtmfTone(tone)
    {
        console.log("--> startDtmfTone tone="+tone);
    }
    function stopDtmfTone()
    {
        console.log("--> stopDtmfTone");
    }

}
