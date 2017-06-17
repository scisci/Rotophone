//
//  SimulationController.h
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Shape.h"
#import "Entities.h"
#import "MicrophoneController.h"

@protocol Scene

@property (retain) NSObject<Shape> *selection;
- (void)addShape:(NSObject<Shape> *)shape;
- (void)removeShape:(NSObject<Shape> *)shape;
@end

@interface SimulationController : NSObject {

}
@property (retain) NSObject<Scene> * scene;
- (void)addMicrophone:(NSObject<MicrophoneProxy> *)proxy;
- (void)addBody:(BodyEntity *)entity;
- (void)removeShape:(id<Shape>) shape;
@end
