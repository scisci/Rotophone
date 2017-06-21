//
//  MainWindowController.m
//  Rotophone
//
//  Created by z on 5/29/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MainWindowController.h"

static void *SceneViewSelectionKVOContext = &SceneViewSelectionKVOContext;


@interface MainWindowController ()

@end

@implementation MainWindowController

- (id)init {
    NSRect frame = NSScreen.mainScreen.frame;
    NSWindow *window  = [[NSWindow alloc] initWithContentRect:frame
                                                    styleMask:NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [window setBackgroundColor:[NSColor blueColor]];
    [window makeKeyAndOrderFront:NSApp];
    
    MainViewController *vc = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    window.contentView = vc.view;
    
    
    [(SceneView *)vc.sceneViewController.view addObserver:self
                forKeyPath:@"selection"
                   options:(NSKeyValueObservingOptionNew |
                            NSKeyValueObservingOptionOld)
                   context:SceneViewSelectionKVOContext];
    
    if (self = [super initWithWindow:window]) {
        self.mainViewController = vc;
    }
    
    return self;

}




- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == SceneViewSelectionKVOContext) {
        NSObject* shape = [change objectForKey:NSKeyValueChangeNewKey];
        if (shape != nil && shape != [NSNull null]) {
            _mainViewController.toolViewController.controlPanel = [(id<Shape>)shape createControlPanel];
        }
    } else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}



@end
