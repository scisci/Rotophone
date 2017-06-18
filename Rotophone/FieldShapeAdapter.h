//
//  FieldShapeAdapter.h
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Shape.h"
#import "Entities.h"

@interface FieldShapeAdapter  : NSObject<RectangleShape> {
}

@property (retain) FieldEntity* entity;
@property (retain) BodyEntity* bodyEntity;

- (id)initWithBody:(BodyEntity *)bodyEntity AndField:(FieldEntity *)entity;

@end
