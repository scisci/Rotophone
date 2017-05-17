//
//  SceneViewController.h
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MicrophoneShape;
@protocol RectangleShape;

@protocol ShapeVisitor<NSObject>
- (void)visitMicrophoneShape:(id<MicrophoneShape>)shape;
- (void)visitRectangleShape:(id<RectangleShape>)shape;
@end


@protocol Shape<NSObject>
- (void)acceptShapeVisitor:(id<ShapeVisitor>)visitor;
@required @property (readonly) NSSize size;
@required @property CGPoint anchor;
@required @property CGFloat rotation;
@required @property CGPoint origin;
@end

@protocol MicrophoneShape<Shape>
@property (readonly) CGFloat microphoneRotation;
@end

@protocol RectangleShape<Shape>
@end

@interface ConcreteMicrophone : NSObject<MicrophoneShape>
@end

@interface ConcreteRectangle : NSObject<RectangleShape>
@end


@interface SceneView : NSView<ShapeVisitor>
- (void)addShape:(id<Shape>)shape;
- (void)removeShape:(id<Shape>)shape;
@end


@interface SceneViewController : NSViewController

@end

