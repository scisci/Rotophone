//
//  ToolViewController.m
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "ToolViewController.h"


@interface ToolbarView() {
    
}

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
@property (retain) NSView *controlPanelView;
@end

@implementation ToolView


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    // [super resizeSubviewsWithOldSize:oldSize];
    CGFloat height = 40.0;
    _toolbarView.frame = CGRectMake(0, _frame.size.height - height, _frame.size.width, height);
    
    if (_controlPanelView != nil) {
        _controlPanelView.frame = CGRectMake(0, 0, _frame.size.width, _frame.size.height - height);
    }
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

@synthesize controlPanel = _controlPanel;

- (void)loadView {
    [super loadView];
    // Do view setup here.
    
    
    
}

- (NSViewController *)controlPanel {
    return _controlPanel;
}

- (IBAction)handleAddBodyButton:(id)sender {
    if (_delegate != nil) {
        [_delegate addBody];
    }
}

- (IBAction)handleDeleteButton:(id)sender {
    if (_delegate != nil) {
        [_delegate deleteSelection];
    }
}

- (void)setControlPanel:(NSViewController *)controlPanel {
    ToolView *toolView = (ToolView *)self.view;
    
    if (controlPanel == _controlPanel) {
        return;
    }
    
    if (_controlPanel != nil) {
        [_controlPanel.view removeFromSuperview];
        toolView.controlPanelView = nil;
    }
    _controlPanel = controlPanel;
    
    if (_controlPanel != nil) {
        [toolView addSubview:_controlPanel.view];
        toolView.controlPanelView = _controlPanel.view;
    }
    [toolView resizeSubviewsWithOldSize:toolView.frame.size];
    
}

@end
