//
//  ToolViewController.h
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ToolbarView : NSView

@end

@interface ToolView : NSView
@property (unsafe_unretained) IBOutlet NSView *toolbarView;
@end

@interface ToolViewController : NSViewController
@property (retain) NSViewController* controlPanel;
@end
