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

import QtQuick 2.15
import QtQml.Models 2.15

import "VoiceCallStatusStub.js" as VoiceCall;

Item {
    id: testVoiceCallMgr

    Component {
        id: compTestVoiceCall
        VoiceCall {
            isIncoming: true
            onStatusChanged: {
                if(status!==VoiceCall.STATUS_ACTIVE)
                {
                    if(testVoiceCallMgr.activeVoiceCall===this) testVoiceCallMgr.activeVoiceCall = null;
//                    if(status === STATUS_NULL) this.destroy();
                }
            }
        }
    }

    property ObjectModel voiceCalls: ObjectModel {
        id: _voiceCalls
        signal rowsInserted(var parent, int first, int last);

        onCountChanged: {
            rowsInserted(null, _voiceCalls.count-1, _voiceCalls.count-1);
        }
        function instance(idx) {
            return get(idx);
        }
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
            voiceCalls.append(compTestVoiceCall.createObject(null,
                       { isIncoming: true,
                         lineId: msisdn,
                         status: VoiceCall.STATUS_INCOMING } ));
        }
        else
        {
            console.log("--> dial: providerId=" + providerId + " msisdn=" + msisdn);
            voiceCalls.append(compTestVoiceCall.createObject(null,
                       { providerId: providerId,
                         lineId: msisdn,
                         status: VoiceCall.STATUS_DIALING } ));
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
