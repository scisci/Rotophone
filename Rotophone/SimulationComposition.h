//
//  SimulationComposition.h
//  Rotophone
//
//  Created by z on 11/27/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MultiChannelAudioTrackMixer.h"

NS_ASSUME_NONNULL_BEGIN

@interface MidiMixerInput : NSObject
- (instancetype)initWithNumChannels:(unsigned int)numChannels;
- (unsigned int)numChannels;
- (bool)setVolume:(float)volume forChannel:(unsigned int)channel;
- (void)copyMix:(MixerInput *)mixerInput;

@end


@protocol SimulationCompositionDelegate

- (void)sendMidiData:(const unsigned char *)data ofSize:(size_t)dataSize;

@end

@interface SimulationComposition : NSObject

- (instancetype)initWithDelegate:(id<SimulationCompositionDelegate>)delegate andFreqs:(NSArray *)freqs;
- (void)loadMidiFile:(NSString *)path;
- (void)updatePosition:(double)position andVelocity:(double)velocity andValid:(bool)velocityValid;
- (void)refresh;

- (void)setMix:(MidiMixerInput *)mixerInput;

@end

NS_ASSUME_NONNULL_END
