//
//  MainViewController.m
//  Rotophone
//
//  Created by z on 5/6/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MainViewController.h"
#import "RootView.h"

#import <AudioToolbox/AudioToolbox.h>


@interface MainViewController ()

@end
@implementation MainViewController

@synthesize document = _document;

- (void)loadView {
    [super loadView];

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

-(Document *)document {
    return _document;
}

-(void)setDocument:(Document *)document {
    _document = document;
    
    if (_document != nil) {
        
    }
}


@end
