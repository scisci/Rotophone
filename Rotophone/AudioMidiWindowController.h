//
//  AudioMidiWindowController.h
//  Rotophone
//
//  Created by z on 11/25/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AudioMidiViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioMidiWindowController : NSWindowController
@property (retain) AudioMidiViewController* audioMidiViewController;
@end

NS_ASSUME_NONNULL_END
