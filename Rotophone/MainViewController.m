//
//  MainViewController.m
//  Rotophone
//
//  Created by z on 5/6/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MainViewController.h"
#import "RootView.h"
#import "SceneViewController.h"
#import "ToolViewController.h"
#import "SideBarViewController.h"

@interface MainViewController ()
@property (retain) NSSound *sound;
@property (retain) SceneViewController *sceneViewController;
@property (retain) SideBarViewController *sideBarViewController;
@property (retain) ToolViewController *toolViewController;
@end
@implementation MainViewController

- (void)loadView {
    [super loadView];
    // Do view setup here.
    
    // Create subview controllers
    
    
    self.sceneViewController = [[SceneViewController alloc] initWithNibName:@"SceneViewController" bundle:nil];
    self.toolViewController = [[ToolViewController alloc] initWithNibName:@"ToolViewController" bundle:nil];
    self.sideBarViewController = [[SideBarViewController alloc] initWithNibName:@"SideBarViewController" bundle:nil];
    
    RootView *rootView = (RootView *)self.view;
    rootView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [rootView addSubview: _sceneViewController.view];
    rootView.sceneView = _sceneViewController.view;
    [rootView addSubview: _toolViewController.view];
    rootView.toolView = _toolViewController.view;
    [rootView addSubview: _sideBarViewController.view];
    rootView.sideBarView = _sideBarViewController.view;
}


/*
- (IBAction)handleSoundButton:(id)sender {
    NSLog(@"sound button");
    NSBundle* bundle = NSBundle.mainBundle;
    NSString* filePath = [bundle pathForResource:@"Two Steps From Hell - Ashes (Halloween)" ofType:@"mp3" inDirectory:@"Resources"];
    
    NSLog(@"Got file path %@", filePath);
    
    _sound = [[NSSound alloc] initWithContentsOfFile:filePath byReference: YES];
    [_sound play];
}
*/
@end
