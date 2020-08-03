//
//  SoundNode.swift
//  AChess
//
//  Created by zhaoheng sun on 7/30/20.
//  Copyright © 2020 zhaoheng sun. All rights reserved.
//

import AVFoundation

class SoundNode: AVAudioUnitMIDIInstrument {

    let auSamplerDescription = AudioComponentDescription(componentType: kAudioUnitType_MusicDevice,
                                                         componentSubType: kAudioUnitSubType_Sampler,
                                                         componentManufacturer: kAudioUnitManufacturer_Apple,
                                                         componentFlags: 0,
                                                         componentFlagsMask: 0)

    override init() {
        super.init(audioComponentDescription: auSamplerDescription)
    }
}
