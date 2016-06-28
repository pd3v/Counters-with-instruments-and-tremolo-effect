
// This code is a modified excerpt of DSPKernel.hpp file from Apple's AudioUnitv3 sample code project.

#ifndef DSPKernel_h
#define DSPKernel_h

#import <AudioToolbox/AudioToolbox.h>

class DSPKernel {
public:
	virtual void process(AUAudioFrameCount frameCount) = 0;
	void processWithEvents(AudioTimeStamp const* timestamp, AUAudioFrameCount frameCount, AURenderEvent const* events);
};

#endif /* DSPKernel_h */
