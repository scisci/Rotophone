//
//  AppDelegate.h
//  Rotophone
//
//  Created by z on 5/5/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SerialPortHandler.h"
#import "ORSSerialPortManager.h"


@interface AppDelegate : NSObject <NSApplicationDelegate>

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
@property (retain) SerialPortHandler* serialPortHandler;
@property (retain) ORSSerialPortManager* serialPortManager;
@end

