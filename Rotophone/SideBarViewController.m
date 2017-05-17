//
//  SideBarViewController.m
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SideBarViewController.h"


@interface SideBarView ()

@end

@implementation SideBarView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor orangeColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}
@end

@interface SideBarViewController ()

@end

@implementation SideBarViewController

- (void)loadView {
    [super loadView];
    // Do view setup here.
}

@end
