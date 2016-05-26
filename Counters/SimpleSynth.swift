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
    var sampleRate: Float = 44_100.0
    
    required override init() {
        super.init()
        self.volume = 0.99

        for _ in 0..<arc4random_uniform(numOfOctaves) { noteFrequency *= 2 }
    }
    
    private func createSoundwave(sampleRate: Float, duration: AVAudioFrameCount, numOfOctaves: UInt32, amplitudeEnvelope: (sample: Int, buf: AVAudioPCMBuffer)->Float) -> AVAudioPCMBuffer {
        var buffer = AVAudioPCMBuffer()
        buffer = AVAudioPCMBuffer(PCMFormat: self.outputFormatForBus(0), frameCapacity: duration)
        buffer.frameLength = duration
        /*print("Duration in samples:\(duration)")
        print("Duration in seconds:\(round(sampleRate / noteFrequency) / 44_100.0)")*/
        
        for i in 0..<Int(buffer.frameLength) {
            let val = fmodf(noteFrequency * Float(i) / sampleRate, 1.0) * 2 - 1 // Sawtooth wave
            //let val = sinf(noteFrequency * Float(i) * 2 * Float(M_PI) / sampleRate) // Sine wave
            //let val =  Float(sinf(noteFrequency * Float(i) * 2 * Float(M_PI) / sampleRate) >= 0.0 ? 1.0 : -1.0) // Square wave
            buffer.floatChannelData.memory[i] = val * amplitudeEnvelope(sample: i, buf: buffer)
            if i == 0 {print(i, val, buffer.floatChannelData.memory[i])}
        }
        /*print(Int(buffer.frameLength) - 1, buffer.floatChannelData.memory[Int(buffer.frameLength-1)])
        print("----")*/
        
        return buffer
    }
    
    override func scheduleBuffer(buffer: AVAudioPCMBuffer?, atTime: AVAudioTime?, options: AVAudioPlayerNodeBufferOptions, completionHandler: AVAudioNodeCompletionHandler?) {
        let duration: AVAudioFrameCount
        let amplitudeEnvelope: (sample: Int, buffer: AVAudioPCMBuffer) -> Float
        //FIXME: The transition from Attack buffer to the Sustain buffer is audible. It souldn't be. Phases match.
        switch options {
        case AVAudioPlayerNodeBufferOptions.Interrupts: // Attack
            duration = AVAudioFrameCount(round(sampleRate / noteFrequency * 2)) // '* 2' for twice the needed amount of samples for a smoother attack envelope
            amplitudeEnvelope = { sample, buffer in
                return Float(sample) / Float(buffer.frameLength)
            }
        case AVAudioPlayerNodeBufferOptions.InterruptsAtLoop: // Release
            duration = AVAudioFrameCount(round(sampleRate / noteFrequency * 2)) // '* 2' for twice the needed amount of samples for a smoother release envelope
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
    
    /*func secondsToFrameSize(sampleRate sampleRate: Float, timeInSec: Float) -> AVAudioFrameCount {
        let samplesMinimum = round(sampleRate / noteFrequency)
        let minimumDuration = samplesMinimum / 44_100.0
        //print("Samples Minimum:\(samplesMinimum)")
        print("Minimum Duration:\(minimumDuration)seg")
        /*let snapDurantion = timeInSec / minimumDuration * minimumDuration
        print("Span Duration:\(snapDurantion)seg")
        return UInt32(sampleRate * snapDurantion)*/
        return UInt32(sampleRate * timeInSec)
    }*/
}
