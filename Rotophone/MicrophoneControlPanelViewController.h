//
//  MicrophoneControlPanelViewController.h
//  Rotophone
//
//  Created by z on 6/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MicrophoneController.h"

@interface MicrophoneControlPanelView : NSView
@property (unsafe_unretained) IBOutlet NSButton *zeroButton;
@property (unsafe_unretained) IBOutlet NSSlider *targetSlider;
@property (unsafe_unretained) IBOutlet NSSlider *rotationSlider;
@property (unsafe_unretained) IBOutlet NSSlider *pickupAngleSlider;
@property (unsafe_unretained) IBOutlet NSSlider *pickupDistSlider;
@end

@interface MicrophoneControlPanelViewController : NSViewController
@property (unsafe_unretained) NSObject<MicrophoneProxy> *microphone;
@end
