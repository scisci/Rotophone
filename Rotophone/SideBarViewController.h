//
//  SideBarViewController.h
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SerialPortHandler.h"

@interface SideBarView : NSView
@end

@interface SideBarViewController : NSViewController<RawStreamHandler>

@end