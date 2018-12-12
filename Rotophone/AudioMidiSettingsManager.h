//
//  AudioMidiSettingsManager.h
//  Rotophone
//
//  Created by z on 11/25/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
class MidiOutCore;
#else
typedef void* MidiOutCore;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AudioMidiSettingsManager : NSObject

+ (AudioMidiSettingsManager *)sharedManager;

- (NSArray *)listMidiPorts;
- (Float64)sampleRate;
- (void)sendMidiData:(const unsigned char *)data ofSize:(size_t)dataSize;
- (MidiOutCore *)midiOutCore;
@property (readwrite) int selectedMidiPort;


@end

NS_ASSUME_NONNULL_END
