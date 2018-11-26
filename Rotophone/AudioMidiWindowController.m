//
//  AudioMidiWindowController.m
//  Rotophone
//
//  Created by z on 11/25/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import "AudioMidiWindowController.h"

@interface AudioMidiWindowController ()

@end

@implementation AudioMidiWindowController

- (instancetype)init {
    NSRect frame = NSScreen.mainScreen.frame;
    CGFloat width = frame.size.width / 2;
    CGFloat height = frame.size.height / 2;
    if (width < 400) {
      width = 400;
    }
  
    if (height < 300) {
      height = 300;
    }
  
    frame = NSInsetRect(frame, (frame.size.width - width)/2, (frame.size.height - height)/2);
  
    NSWindow *window  = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask: NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];

    [window makeKeyAndOrderFront:NSApp];
  
    AudioMidiViewController *vc = [[AudioMidiViewController alloc] initWithNibName:@"AudioMidiViewController" bundle:nil];
    window.contentView = vc.view;
  

  
    if (self = [super initWithWindow:window]) {
        self.audioMidiViewController = vc;
    }
  
    return self;

}

@end
