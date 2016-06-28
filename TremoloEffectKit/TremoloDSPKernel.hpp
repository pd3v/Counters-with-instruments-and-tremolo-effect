
// This code is a modified, to be a Tremolo, excerpt of FilterDSPKernel.hpp file from Apple's AudioUnitv3 sample code project.
// A DSPKernel subclass implementing the realtime signal processing portion of the AUAudioTremolo audio unit.

#ifndef TremoloDSPKernel_hpp
#define TremoloDSPKernel_hpp

#import "DSPKernel.hpp"
#import "ParameterRamper.hpp"

enum {
    TremoloParamDepth = 0,
    TremoloParamRateFrequency = 1
};

/*
	TremoloDSPKernel
	Performs tremolo signal processing.
	As a non-ObjC class, this is safe to use from render thread.
*/

class TremoloDSPKernel : public DSPKernel {
public:
    TremoloDSPKernel() {}
	
	void init(int inChannelCount, double inSampleRate) {
        channelCount = int(inChannelCount);
		sampleRate = float(inSampleRate);
		
        depthRamper.init();
        rateFrequencyRamper.init();
        
        waveTable();
	}
	
	void reset() {
        samplesProcessed = 0;
        depthRamper.reset();
        rateFrequencyRamper.reset();
	}
	
	void setParameter(AUParameterAddress address, AUValue value) {
        switch (address) {
         case TremoloParamDepth:
         depthRamper.setUIValue(value);
         break;
         
         case TremoloParamRateFrequency:
         rateFrequencyRamper.setUIValue(value);
         break;
        }
	}

	AUValue getParameter(AUParameterAddress address) {
        switch (address) {
            case TremoloParamDepth:
                return depthRamper.getUIValue();
         
            case TremoloParamRateFrequency:
                return rateFrequencyRamper.getUIValue();
         
         default: return 1.0f;
        }
	}
	
	void setBuffers(AudioBufferList* inBufferList, AudioBufferList* outBufferList) {
		inBufferListPtr = inBufferList;
		outBufferListPtr = outBufferList;
	}
    
    void waveTable() {
        for (int i = 0; i < kWaveArraySize; ++i) {
            double radians = i * 2.0 * M_PI / kWaveArraySize;
            sinewave[i] = (sin (radians) + 1.0) * 0.5;
        }
        
        for (int i = 0; i < kWaveArraySize; ++i) {
            double radians = i * 2.0 * M_PI / kWaveArraySize;
            radians = radians + 0.32; // shift the wave over for a smoother start
            squarewave[i] =
            (
             sin (radians) +	// Sums the odd harmonics, scaled for a nice final waveform
             0.3 * sin (3 * radians) +
             0.15 * sin (5 * radians) +
             0.075 * sin (7 * radians) +
             0.0375 * sin (9 * radians) +
             0.01875 * sin (11 * radians) +
             0.009375 * sin (13 * radians) +
             0.8			// Shifts the value so it doesn't go negative.
             ) * 0.63;		// Scales the waveform so the peak value is close 
            //  to unity gain.
        }
    }
    
	void process(AUAudioFrameCount frameCount) override {
        
        Float32 tremoloGain, samplesPerTremoloCycle, tremoloFrequency, tremoloDepth;
        
        waveArrayPointer = &squarewave[0]; //&sinewave[0];
        
        tremoloDepth = getParameter(TremoloParamDepth);
        tremoloFrequency =  getParameter(TremoloParamRateFrequency);
        
        samplesPerTremoloCycle	=  sampleRate / tremoloFrequency;
        nextScale = kWaveArraySize / samplesPerTremoloCycle;
        if (currentScale == -1) { currentScale = nextScale; }
        
        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            int index = static_cast<long>(samplesProcessed * nextScale) % kWaveArraySize;
            
            if ((nextScale != currentScale) && (index == 0)) {
                currentScale = nextScale;
                samplesProcessed = 0;
            }
            
            for (int channel = 0; channel < channelCount; ++channel) {
                float* in  = (float*)inBufferListPtr->mBuffers[channel].mData + frameIndex;
                float* out = (float*)outBufferListPtr->mBuffers[channel].mData + frameIndex;
                tremoloGain	= (waveArrayPointer[index] * tremoloDepth - tremoloDepth + 100.0) * 0.01;
                float x0 = *in;
                float y0 = x0 * tremoloGain;
                *out = y0;
                
                samplesProcessed += 1;
            }
        }
    }

private:
    enum {kWaveArraySize = 2000};
    
    int channelCount = 2;
	float sampleRate = 44100.0;
    float sinewave[kWaveArraySize];
    float squarewave[kWaveArraySize];
    float *waveArrayPointer;
    float sampleFrequency;
    long  samplesProcessed = 0;
    float currentScale = -1;
    float nextScale;
    
	AudioBufferList* inBufferListPtr = nullptr;
	AudioBufferList* outBufferListPtr = nullptr;

public:
    ParameterRamper depthRamper = 50.0;
    ParameterRamper rateFrequencyRamper = 6.0;
};

#endif /* FilterDSPKernel_hpp */
