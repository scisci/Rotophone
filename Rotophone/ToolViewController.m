//
//  ToolViewController.m
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "ToolViewController.h"


@interface ToolbarView()

@end

@implementation ToolbarView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor blueColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}
@end

@interface ToolView ()

@end

@implementation ToolView


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    // [super resizeSubviewsWithOldSize:oldSize];
    CGFloat height = 40.0;
    _toolbarView.frame = CGRectMake(0, _frame.size.height - height, _frame.size.width, height);
}

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
    
    ToolView *toolView = (ToolView *)self.view;
    
}

@end
