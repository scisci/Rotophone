//
//  SideBarViewController.h
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SerialPortHandler.h"
#import "MicrophoneController.h"


@interface TransportView : NSView
@property (unsafe_unretained) NSObject<MicrophoneTransport> *transport;
@property (unsafe_unretained) IBOutlet NSButton *startStopButton;
@property (unsafe_unretained) IBOutlet NSButton *calibrateButton;
@property (unsafe_unretained) IBOutlet NSSlider *volumeSlider;
@property (unsafe_unretained) IBOutlet
    NSButton *muteButton;
@property (unsafe_unretained) IBOutlet
NSButton *performButton;
@property (unsafe_unretained) IBOutlet NSButton *useMockButton;
@property (unsafe_unretained) IBOutlet NSButton *enableRawSerialButton;
@end

@interface StatusView : NSView
@property (retain) id<MicrophoneStatus> status;
@property (unsafe_unretained) IBOutlet NSTextField *statusLabel;
@end


@interface SideBarView : NSView
@property (unsafe_unretained) IBOutlet StatusView *statusView;
@property (unsafe_unretained) IBOutlet TransportView *transportView;
@end

@interface SideBarViewController : NSViewController<RawStreamHandler>

@end
