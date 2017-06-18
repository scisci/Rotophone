//
//  SimulationAudioUnit.h
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "PdAudioUnit.h"

@protocol UpdateableSimulation
-(void)updateSimulation;
@end

@interface SimulationAudioUnit : PdAudioUnit
@property (unsafe_unretained) id<UpdateableSimulation> simulation;
@end
