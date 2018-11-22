//
//  VideoViewController.h
//  VideoMixerTest
//
//  Created by z on 11/12/18.
//  Copyright © 2018 scisci. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SandboxFileManager.h"
#import "MultiChannelAudioTrackMixer.h"

NS_ASSUME_NONNULL_BEGIN


@interface VideoViewController : NSViewController

- (MixerInput *)openVideo:(URLResource *)urlResource;
- (void)setMix:(MixerInput *)mix;
- (MultiChannelAudioTrackMixer *)mixer;

@end

@interface VideoView : NSView

@end

NS_ASSUME_NONNULL_END
