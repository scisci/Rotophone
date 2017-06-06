//
//  MainWindowController.m
//  Rotophone
//
//  Created by z on 5/29/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MainWindowController.h"


@interface MainWindowController ()

@end

@implementation MainWindowController

- (id)init {
    NSRect frame = NSMakeRect(0, 0, 600, 600);
    NSWindow *window  = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [window setBackgroundColor:[NSColor blueColor]];
    [window makeKeyAndOrderFront:NSApp];
    
    MainViewController *vc = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    window.contentView = vc.view;
    
    if (self = [super initWithWindow:window]) {
        self.mainViewController = vc;
    }
    
    return self;

}


@end
