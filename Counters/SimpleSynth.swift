//
//
//  Created by Paulo.
//  Copyright © 2016 xyz. All rights reserved.
//

import Foundation
import AVFoundation


class SimpleSynth: AVAudioPlayerNode {
    var noteFrequency: Float = 65.4 // note C2
    var numOfOctaves: UInt32 = 5
    var sampleRate: Float = 44_100.0
    
    required override init() {
        super.init()
        for _ in 0..<arc4random_uniform(numOfOctaves) { noteFrequency *= 2 }
    }
    
    private func createSoundwave(sampleRate: Float, duration: AVAudioFrameCount, numOfOctaves: UInt32, amplitudeEnvelope: (sample: Int, buf: AVAudioPCMBuffer)->Float) -> AVAudioPCMBuffer {
        var buffer = AVAudioPCMBuffer()
        buffer = AVAudioPCMBuffer(PCMFormat: self.outputFormatForBus(0), frameCapacity: duration)
        buffer.frameLength = duration
        
        for i in 0..<Int(buffer.frameLength) {
            for channel in 0..<Int(buffer.format.channelCount) {
                let val = fmodf(noteFrequency * Float(i) / sampleRate, 1.0) * 2 - 1 // Sawtooth wave
                //let val = sinf(noteFrequency * Float(i) * 2 * Float(M_PI) / sampleRate) // Sine wave
                //let val =  Float(sinf(noteFrequency * Float(i) * 2 * Float(M_PI) / sampleRate) >= 0.0 ? 1.0 : -1.0) // Square wave
                buffer.floatChannelData[channel][i] = val * amplitudeEnvelope(sample: i, buf: buffer)
            }
        }
        return buffer
    }
    
    override func scheduleBuffer(buffer: AVAudioPCMBuffer?, atTime: AVAudioTime?, options: AVAudioPlayerNodeBufferOptions, completionHandler: AVAudioNodeCompletionHandler?) {
        let duration: AVAudioFrameCount
        let amplitudeEnvelope: (sample: Int, buffer: AVAudioPCMBuffer) -> Float
        //FIXME: When buffers are of different lenghts transition between them are audible. It souldn't be. Phases match.
        switch options {
        case AVAudioPlayerNodeBufferOptions.Interrupts: // Attack
            duration = AVAudioFrameCount(round(sampleRate / noteFrequency))
            amplitudeEnvelope = { sample, buffer in
                return Float(sample) / Float(buffer.frameLength)
            }
        case AVAudioPlayerNodeBufferOptions.InterruptsAtLoop: // Release
            duration = AVAudioFrameCount(round(sampleRate / noteFrequency))
            amplitudeEnvelope = { sample, buffer in
                return 1 - (Float(sample) / Float(buffer.frameLength))
            }
        default: // AVAudioPlayerNodeBufferOptions.Loops: Sustain
            duration = AVAudioFrameCount(round(sampleRate / noteFrequency))
            amplitudeEnvelope = { _,_ in return -0.99 }
        }
        
        var waveToBuffer: AVAudioPCMBuffer? = buffer
        if buffer?.frameLength == nil {
            waveToBuffer = createSoundwave(sampleRate, duration: duration, numOfOctaves: numOfOctaves, amplitudeEnvelope: amplitudeEnvelope)
        }
        super.scheduleBuffer(waveToBuffer!,
                             atTime: atTime,
                             options: options,
                             completionHandler: completionHandler)
    }
}
