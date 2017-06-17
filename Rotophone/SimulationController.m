//
//  SimulationController.m
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SimulationController.h"

#import "MicrophoneShapeAdapter.h"
#import "FieldShapeAdapter.h"

@interface SimulationBody : NSObject {
}



@property (retain) FieldEntity* field;
@property (retain) BodyEntity* body;
@property (retain) FieldShapeAdapter* fieldShape;

@end

@implementation SimulationBody
- (id) initWithBody:(BodyEntity *)body {
    if (self = [super init]) {
        self.body = body;
        self.field = [[body.fields allObjects] objectAtIndex:0];
        self.fieldShape = [[FieldShapeAdapter alloc] initWithEntity:_field];
    }
    return self;
}
@end


@interface SimulationController () {
    NSArray* _bodies;
}

@end

@implementation SimulationController

- (id)init {
    if (self = [super init]) {
        _bodies = [[NSArray alloc] init];
    }
    return self;
}

- (void)addMicrophone:(NSObject<MicrophoneProxy> *)proxy {
    MicrophoneShapeAdapter* microphoneShape = [[MicrophoneShapeAdapter alloc] initWithProxy:proxy];
    
    [_scene addShape:microphoneShape];
    
}

- (void)addBody:(BodyEntity *)entity {
    // Shape
    SimulationBody *body = [[SimulationBody alloc] initWithBody:entity];
    
    _bodies = [_bodies arrayByAddingObject:body];
    
    [_scene addShape:body.fieldShape];
}

- (void)removeShape:(id<Shape>)shape {
    for (SimulationBody* body in _bodies) {
        if (body.fieldShape == shape) {
            [body.body.managedObjectContext deleteObject:body.body];
            [_scene removeShape:body.fieldShape];
            NSMutableArray *newBodies = [NSMutableArray arrayWithArray:_bodies];
            [newBodies removeObject:body];
            _bodies = [NSArray arrayWithArray:newBodies];
            return;
        }
    }
}
@end
