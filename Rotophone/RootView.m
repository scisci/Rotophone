//
//  RootViewController.m
//  Rotophone
//
//  Created by z on 5/5/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "RootView.h"

@interface RootView ()

@end

@implementation RootView


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
   // [super resizeSubviewsWithOldSize:oldSize];
    
    _sideBarView.frame = CGRectMake(_frame.size.width - 200, 0, 200, _frame.size.height);
    
    _sceneView.frame = CGRectMake(0, 150, _frame.size.width - 200, _frame.size.height - 150);
    
    _toolView.frame = CGRectMake(0, 0, _frame.size.width - 200, 150);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor redColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}
@end
