
// This code is a modified excerpt of ParameterRampler.hpp file from Apple's AudioUnitv3 sample code project.

#ifndef ParameterRamper_h
#define ParameterRamper_h

#import <AudioToolbox/AudioToolbox.h>
#import <libkern/OSAtomic.h>

class ParameterRamper {
	float clampLow, clampHigh;
    float _uiValue;
    float _goal;
    float inverseSlope;
    AUAudioFrameCount samplesRemaining;
	volatile int32_t changeCounter = 0;
	int32_t updateCounter = 0;

    void setImmediate(float value) {
        _goal = _uiValue = value;
        inverseSlope = 0.0;
        samplesRemaining = 0;
    }

public:
	ParameterRamper(float value) {
		setImmediate(value);
	}
	
	void init() {
		setImmediate(_uiValue);
	}

	void reset() {
		changeCounter = updateCounter = 0;
	}

    void setUIValue(float value) {
        _uiValue = value;
		OSAtomicIncrement32Barrier(&changeCounter);
    }
	
	float getUIValue() const { return _uiValue; }
	
    float get() const {
        return inverseSlope * float(samplesRemaining) + _goal;
    }
	
    void step() {
        if (samplesRemaining != 0) {
			--samplesRemaining;
		}
    }

    float getAndStep() {
        if (samplesRemaining != 0) {
            float value = get();
            --samplesRemaining;
            return value;
        }
		else {
            return _goal;
        }
    }

    void stepBy(AUAudioFrameCount n) {
        if (n >= samplesRemaining) {
			samplesRemaining = 0;
        }
		else {
			samplesRemaining -= n;
		}
    }
};

#endif /* ParameterRamper_h */
