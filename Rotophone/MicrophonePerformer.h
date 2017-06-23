//
//  MicrophonePerformer.h
//  Rotophone
//
//  Created by z on 6/19/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MicrophoneController.h"

@class PerformMode;

@interface PerformanceTarget : NSObject {
}

@property (readwrite) float angleMin;
@property (readwrite) float angleMax;
@end

@interface MicrophonePerformer : NSObject
@property (retain) NSObject<MicrophoneProxy> *microphone;
@property (readonly) NSArray* targets;
- (void)addTarget:(PerformanceTarget *)target;
- (void)removeTarget:(PerformanceTarget *)target;
- (void)start;
- (void)stop;
- (void)updatePosition:(float)position andVelocity:(double)velocity andValid:(BOOL)valid;

- (void)endMode:(PerformMode *)mode;


@end
