//
//  SceneViewController.h
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Shape.h"


@interface ConcreteRectangle : NSObject<RectangleShape>
@end


@interface SceneView : NSView<ShapeVisitor>

@property (retain) NSObject<Shape> *selection;
- (void)addShape:(NSObject<Shape> *)shape;
- (void)removeShape:(NSObject<Shape> *)shape;
@end


@interface SceneViewController : NSViewController
@end

