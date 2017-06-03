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
@property (retain) NSTextView* rawView;
@end

@implementation SideBarViewController

- (void)loadView {
    [super loadView];
    // Do view setup here.
    self.rawView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)];
    [self.view addSubview:_rawView];
}

- (void)handleRawData:(NSData *)rawData {
    // Append it to the text field
    NSString *text = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
    if (text != nil) {
        [_rawView insertText:text];
    }
}

@end
