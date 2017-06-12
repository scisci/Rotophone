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


@end
