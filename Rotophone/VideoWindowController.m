#import "VideoWindowController.h"



@interface VideoWindowController ()

@end

@implementation VideoWindowController

- (id)init {
    NSRect frame = NSScreen.mainScreen.frame;
    NSWindow *window  = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [window setBackgroundColor:[NSColor blueColor]];
    [window makeKeyAndOrderFront:NSApp];
  
    VideoViewController *vc = [[VideoViewController alloc] initWithNibName:nil bundle:nil];
    window.contentView = vc.view;
  

    if (self = [super initWithWindow:window]) {
        self.videoViewController = vc;
    }
  
    return self;

}





@end
