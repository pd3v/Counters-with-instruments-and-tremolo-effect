
// This code is a modified excerpt of FilterDemo.mm file from Apple's AudioUnitv3 sample code project.

#import "AUAudioTremolo.h"
#import <AVFoundation/AVFoundation.h>
#import "TremoloDSPKernel.hpp"
#import "BufferedAudioBus.hpp"

@interface AUAudioTremolo ()

@property AUAudioUnitBus *outputBus;
@property AUAudioUnitBusArray *inputBusArray;
@property AUAudioUnitBusArray *outputBusArray;

@property (nonatomic, readwrite) AUParameterTree *parameterTree;

@end


@implementation AUAudioTremolo {
	// C++ members need to be ivars; they would be copied on access if they were properties.
    TremoloDSPKernel _kernel;
    BufferedInputBus _inputBus;
}
@synthesize parameterTree = _parameterTree;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];

    if (self == nil) {
    	return nil;
    }
    
	// Initialize a default format for the busses.
    AVAudioFormat *defaultFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];

	// Create a DSP kernel to handle the signal processing.
	_kernel.init(defaultFormat.channelCount, defaultFormat.sampleRate);
	
    AUParameter *depthParam = [AUParameterTree createParameterWithIdentifier:@"depth" name:@"Depth" address:TremoloParamDepth min:0.0 max:100.0 unit:kAudioUnitParameterUnit_Generic unitName:nil flags: 0 valueStrings:nil dependentParameters:nil];
    
    AUParameter *rateFrequencyParam = [AUParameterTree createParameterWithIdentifier:@"rateFrequency" name:@"RateFrequency" address:TremoloParamRateFrequency min:0.0 max:20.0 unit:kAudioUnitParameterUnit_Generic unitName:nil flags:0 valueStrings:nil dependentParameters:nil];
    
    depthParam.value = 50.0;
    rateFrequencyParam.value = 2.0;
    _kernel.setParameter(TremoloParamDepth, depthParam.value);
    _kernel.setParameter(TremoloParamRateFrequency, rateFrequencyParam.value);
	
	
    _parameterTree = [AUParameterTree createTreeWithChildren:@[depthParam,rateFrequencyParam]];

	_inputBus.init(defaultFormat, 8);
    _outputBus = [[AUAudioUnitBus alloc] initWithFormat:defaultFormat error:nil];

	_inputBusArray  = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeInput  busses: @[_inputBus.bus]];
	_outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeOutput busses: @[_outputBus]];

	// Make a local pointer to the kernel to avoid capturing self.
	__block TremoloDSPKernel *tremoloKernel = &_kernel;

	_parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
		tremoloKernel->setParameter(param.address, value);
	};
	
	_parameterTree.implementorValueProvider = ^(AUParameter *param) {
		return tremoloKernel->getParameter(param.address);
	};
	
	_parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
		AUValue value = valuePtr == nil ? param.value : *valuePtr;
        switch (param.address) {
            case TremoloParamDepth:
                return [NSString stringWithFormat:@"%.2f", value];
                
            case TremoloParamRateFrequency:
                return [NSString stringWithFormat:@"%.2f", value];
                
            default:
                return @"?";
        }
	};

	self.maximumFramesToRender = 512;
	
	return self;
}

#pragma mark - AUAudioUnit Overrides

- (AUAudioUnitBusArray *)inputBusses {
    return _inputBusArray;
}

- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
	if (![super allocateRenderResourcesAndReturnError:outError]) {
		return NO;
	}
	
    if (self.outputBus.format.channelCount != _inputBus.bus.format.channelCount) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:kAudioUnitErr_FailedInitialization userInfo:nil];
        }
        
        self.renderResourcesAllocated = NO;
        
        return NO;
    }
	
	_inputBus.allocateRenderResources(self.maximumFramesToRender);
	
	_kernel.init(self.outputBus.format.channelCount, self.outputBus.format.sampleRate);
	_kernel.reset();
	
	return YES;
}
	
- (void)deallocateRenderResources {
	[super deallocateRenderResources];
	
	_inputBus.deallocateRenderResources();
}
	
- (AUInternalRenderBlock)internalRenderBlock {
	/*
		Capture in locals to avoid ObjC member lookups. If "self" is captured in
        render, we're doing it wrong.
	*/
	__block TremoloDSPKernel *state = &_kernel;
	__block BufferedInputBus *input = &_inputBus;
    
    return ^AUAudioUnitStatus(
			 AudioUnitRenderActionFlags *actionFlags,
			 const AudioTimeStamp       *timestamp,
			 AVAudioFrameCount           frameCount,
			 NSInteger                   outputBusNumber,
			 AudioBufferList            *outputData,
			 const AURenderEvent        *realtimeEventListHead,
			 AURenderPullInputBlock      pullInputBlock) {
		AudioUnitRenderActionFlags pullFlags = 0;

		AUAudioUnitStatus err = input->pullInput(&pullFlags, timestamp, frameCount, 0, pullInputBlock);
		
        if (err != 0) {
			return err;
		}
		
		AudioBufferList *inAudioBufferList = input->mutableAudioBufferList;
		
		AudioBufferList *outAudioBufferList = outputData;
		if (outAudioBufferList->mBuffers[0].mData == nullptr) {
			for (UInt32 i = 0; i < outAudioBufferList->mNumberBuffers; ++i) {
				outAudioBufferList->mBuffers[i].mData = inAudioBufferList->mBuffers[i].mData;
			}
		}
		
		state->setBuffers(inAudioBufferList, outAudioBufferList);
		state->processWithEvents(timestamp, frameCount, realtimeEventListHead);

		return noErr;
	};
}

@end


