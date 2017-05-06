//
//  AppDelegate.m
//  Rotophone
//
//  Created by z on 5/5/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@interface AppDelegate ()
@property (retain) NSWindow* window;
@property (retain) MainViewController* rootViewController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    // Create a window
    NSRect frame = NSMakeRect(0, 0, 200, 200);
    _window  = [[NSWindow alloc] initWithContentRect:frame
                                                     styleMask:NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];
    [_window setBackgroundColor:[NSColor blueColor]];
    [_window makeKeyAndOrderFront:NSApp];
    
    _rootViewController = [[MainViewController alloc] initWithNibName:@"MainViewController"
                                                                 bundle:nil];
    
    _window.contentView = _rootViewController.view;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
