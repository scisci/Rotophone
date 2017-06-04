//
//  Shape.h
//  Rotophone
//
//  Created by z on 5/30/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#ifndef Shape_h
#define Shape_h

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
@required @property id shapeChanged;
@end

@protocol MicrophoneShape<Shape>
@property CGFloat microphoneRotation;
@property CGFloat microphoneTarget;
@end

@protocol RectangleShape<Shape>
@end


#endif /* Shape_h */
