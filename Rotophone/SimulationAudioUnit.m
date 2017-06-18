//
//  SimulationAudioUnit.m
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SimulationAudioUnit.h"
#import "PdAudioUnit.h"
#import "PdBase.h"
#import "AudioHelpers.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation SimulationAudioUnit

/*
static OSStatus AudioRenderCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData) {
    
    SimulationAudioUnit *pdAudioUnit = (SimulationAudioUnit *)inRefCon;
    Float32 *auBuffer = (Float32 *)ioData->mBuffers[0].mData;
    
    if (pdAudioUnit->inputEnabled_) {
        AudioUnitRender(pdAudioUnit->audioUnit_, ioActionFlags, inTimeStamp, kInputElement, inNumberFrames, ioData);
    }
    
    int ticks = inNumberFrames >> pdAudioUnit->blockSizeAsLog_; // this is a faster way of computing (inNumberFrames / blockSize)
    [PdBase processFloatWithInputBuffer:auBuffer outputBuffer:auBuffer ticks:ticks];
    return noErr;
}


- (AURenderCallback)renderCallback {
    return AudioRenderCallback;
}
*/
@end
