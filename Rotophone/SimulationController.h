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
#import "PdFile.h"

@class SimulationBody;
@class SimulationMicrophone;

@protocol SimulationBodyDelegate<NSObject>
- (void)simulationBodyMixerChanged:(SimulationBody *)simulationBody;
- (void)simulationBodyChanged:(SimulationBody *)simulationBody;
- (void)simulationMicChanged:(SimulationMicrophone *)simulationMicrophone;
@end


@protocol Scene

@property (retain) NSObject<Shape> *selection;
- (void)addShape:(NSObject<Shape> *)shape;
- (void)removeShape:(NSObject<Shape> *)shape;
- (void)addDebugGraphics:(NSObject<DebugGraphics> *)debugGraphics;
- (void)removeDebugGraphics:(NSObject<DebugGraphics> *)debugGraphics;
@end

@interface SimulationController : NSObject<SimulationBodyDelegate, DebugGraphics> {

}
@property (retain) NSObject<Scene> * scene;
- (id)initWithPatch:(PdFile *)patch;
- (void)addMicrophone:(NSObject<MicrophoneProxy> *)proxy;
- (void)addBody:(BodyEntity *)entity;
- (void)removeShape:(id<Shape>) shape;
- (void)stop;
- (void)start;
- (void)startPerform;
- (void)stopPerform;
@end
