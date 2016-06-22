
// This code is a modified excerpt of DSPKernel.mm file from Apple's AudioUnitv3 sample code project.

#import "DSPKernel.hpp"

void DSPKernel::processWithEvents(AudioTimeStamp const *timestamp, AUAudioFrameCount frameCount, AURenderEvent const *events) {

	AUEventSampleTime now = AUEventSampleTime(timestamp->mSampleTime);
	AUAudioFrameCount framesRemaining = frameCount;
	AURenderEvent const *event = events;
	
	while (framesRemaining > 0) {
		// If there are no more events, we can process the entire remaining segment and exit.
		if (event == nullptr) {
			process(framesRemaining);
			return;
		}

		AUAudioFrameCount const framesThisSegment = AUAudioFrameCount(event->head.eventSampleTime - now);
		
		// Compute everything before the next event.
		if (framesThisSegment > 0) {
			process(framesThisSegment);
			// Advance frames.
			framesRemaining -= framesThisSegment;
			// Advance time.
			now += AUEventSampleTime(framesThisSegment);
		}
	}
}

