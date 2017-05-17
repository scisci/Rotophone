//
//  ToolViewController.m
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "ToolViewController.h"

@interface ToolView ()

@end

@implementation ToolView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor greenColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}
@end

@interface ToolViewController ()

@end

@implementation ToolViewController

- (void)loadView {
    [super loadView];
    // Do view setup here.
}

@end
