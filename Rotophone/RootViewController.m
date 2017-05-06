//
//  RootViewController.m
//  Rotophone
//
//  Created by z on 5/5/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "RootViewController.h"

@interface RootView ()
@property (unsafe_unretained) IBOutlet NSView *sceneView;
@property (unsafe_unretained) IBOutlet NSView *sideBarView;
@property (unsafe_unretained) IBOutlet NSView *toolView;


@end

@implementation RootView


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    
    _sideBarView.frame = CGRectMake(_frame.size.width - 200, 0, 200, _frame.size.height);
    
    _sceneView.frame = CGRectMake(0, 0, _frame.size.width - 200, _frame.size.height - 150);
    
    _toolView.frame = CGRectMake(0, _frame.size.height - 150, _frame.size.width - 200, 150);
}
@end

@interface RootViewController ()

@end

@implementation RootViewController

- (void)loadView {
    [super loadView];
    
    // Do any additional setup after loading the view.

}




- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}


@end
