//
//  MainViewController.h
//  Rotophone
//
//  Created by z on 5/6/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"

#import "SceneViewController.h"
#import "ToolViewController.h"
#import "SideBarViewController.h"

@interface MainViewController : NSViewController

@property (retain) SceneViewController *sceneViewController;
@property (retain) SideBarViewController *sideBarViewController;
@property (retain) ToolViewController *toolViewController;


@property (unsafe_unretained) Document* document;
@end
