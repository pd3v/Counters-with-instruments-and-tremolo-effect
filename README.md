# Counters with Instruments branch
This branch is totally based on Counters but with sound! This time each Counter has a built-in SimpleSynth playing one note. The notes are randomly generated out of C, E, G notes (C Major chord) in various octaves. Slowing down counters' counting increases reverb wet/dry parameter. 
All programmed using AVAudioEngine, AVAudioPlayerNode classes, with code generated soundwaves into AVAudioPCMBuffer buffers, plus AVAudioMixerNode and AVAudioUnitReverb.

## App's initial screen
![intial_screen](https://github.com/pd3v/Counters/blob/master/Screenshots/Initial%20screen.PNG)

## 3x3 counters screen with speed changing indicator
![3x3_counters_screen_with_speed_changing_ indicator](https://github.com/pd3v/Counters/blob/master/Screenshots/counters%20running.PNG)

##Autolayout doing its work on a 6x6 counters screen
![3x3_counters_screen_in_portrait_orientation](https://github.com/pd3v/Counters/blob/master/Screenshots/counters%20running%202.png)

String "yeah!" is shown when counter finishes counting. This string is settable using a delegate method in the viewcontroller.
