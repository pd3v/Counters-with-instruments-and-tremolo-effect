## Counters with Instruments ... and Tremolo audio effect branch
This branch is totally based on Counters with Instruments + Tremolo audio effect! 

This is a "custom-made" effect subclassing AUAudioUnit. The Tremolo effect algorithm runs is in the function "process" inside TremoloDSPKernel class. 
### ⚡️⚡️ Shake the device if you want to change Tremolo rate frequency! ⚡️⚡️🎶

Counter with Instruments has a built-in SimpleSynth playing one note. The notes are randomly generated out of C, E, G notes (C Major chord) in various octaves. Slowing down counters' counting increases reverb wet/dry parameter. 
All programmed using AVAudioEngine, AVAudioPlayerNode classes, with code generated soundwaves into AVAudioPCMBuffer buffers, plus AVAudioMixerNode and AVAudioUnitReverb.

## App's initial screen (added reverb wet/dry info)
![intial_screen](https://github.com/pd3v/Counters/blob/Counters_with_Instruments/Screenshots/Initial%20screen%20(with%20Instruments).PNG)

## 3x3 counters screen with speed changing indicator and sound playing with 40% of reverb
![3x3_counters_screen_with_speed_changing_and_sound_playing indicator](https://github.com/pd3v/Counters/blob/Counters_with_Instruments/Screenshots/Counters%20running%20and%20playing%20sound.PNG)
