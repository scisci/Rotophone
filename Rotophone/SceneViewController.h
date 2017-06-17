//
//  SceneViewController.h
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SimulationController.h"




@interface SceneView : NSView<ShapeVisitor, Scene>

@end


@interface SceneViewController : NSViewController
@end

