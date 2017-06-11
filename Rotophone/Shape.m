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

@end
