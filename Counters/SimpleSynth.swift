//
//  SimpleSynth.swift
//  SynthNative
//
//  Created by Paulo on 14/05/16.
//  Copyright © 2016 xyz. All rights reserved.
//

import Foundation
import AVFoundation

class SimpleSynth: AVAudioPlayerNode {
    var noteFrequency: Float = 65.4 // note C2
    var numOfOctaves: UInt32 = 5
    var sampleRate: Float = 44100.0
    
    required override init() {
        super.init()
        self.volume = 0.5
    }
    
    func createSoundwave() -> AVAudioPCMBuffer {
        var buffer = AVAudioPCMBuffer()
        
        // Randomly setting soundwave frequency for the note in a range of numOfOctaves octaves
        // For example, for C2 note, frequency is 65.4Hz, but if C4 then frequency is 261.6Hz
        for _ in 0..<arc4random_uniform(numOfOctaves) { noteFrequency *= 2 }
        
        let frameSize = UInt32(round(sampleRate/noteFrequency))
        
        buffer = AVAudioPCMBuffer(PCMFormat: self.outputFormatForBus(0), frameCapacity: frameSize)
        buffer.frameLength = frameSize
    
        for i in 0..<Int(buffer.frameLength) {
            let val = noteFrequency * Float(i) / sampleRate // Sawtooth wave
            //let val = sinf(noteFrequency * Float(i) * 2 * Float(M_PI) / sampleRate) // Sine wave
            //let val =  Float(sinf(noteFrequency * Float(i) * 2 * Float(M_PI) / sampleRate) >= 0.0 ? 1.0 : -1.0) // Square wave
            buffer.floatChannelData.memory[i] = val * 0.99
        }
        return buffer
    }
    
    override func scheduleBuffer(buffer: AVAudioPCMBuffer?, atTime: AVAudioTime?, options: AVAudioPlayerNodeBufferOptions, completionHandler: AVAudioNodeCompletionHandler?) {
        var waveToBuffer: AVAudioPCMBuffer? = buffer
        if buffer == nil {
            waveToBuffer = createSoundwave()
        }
        super.scheduleBuffer(waveToBuffer!,
                             atTime: atTime,
                             options: options,
                             completionHandler: completionHandler)
    }
}
