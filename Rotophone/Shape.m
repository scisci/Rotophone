//
//  NSObject_Shape.h
//  Rotophone
//
//  Created by z on 6/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Shape.h"

@implementation ShapeHelper

+ (NSArray *)shapeChangedKeyPaths {
    return @[@"anchor", @"origin", @"rotation"];
}

+ (CGFloat)clockwiseToCounterClockwise:(CGFloat)radians {
    return 2 * M_PI - radians;
}

+ (CGFloat)counterClockwiseToClockwise:(CGFloat)radians {
    return 2 * M_PI - radians;
}

+ (void)applyShapeTransform:(id<Shape>)shape ToTransform:(NSAffineTransform *)transform {
    [transform translateXBy:shape.origin.x yBy:shape.origin.y];
    [transform rotateByRadians:shape.rotation];
    [transform translateXBy:-shape.anchor.x yBy:-shape.anchor.y];
}

@end
