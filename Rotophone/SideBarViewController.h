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
@property (unsafe_unretained) id<MicrophoneTransport> transport;
@property (unsafe_unretained) IBOutlet NSButton *startStopButton;
@property (unsafe_unretained) IBOutlet NSButton *calibrateButton;

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
