//
//  MicrophonePerformer.h
//  Rotophone
//
//  Created by z on 6/19/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MicrophoneController.h"

@interface PerformanceTarget : NSObject {
}

@property (readwrite) float angleMin;
@property (readwrite) float angleMax;
@end

@interface MicrophonePerformer : NSObject
@property (retain) NSObject<MicrophoneProxy> *microphone;

- (void)addTarget:(PerformanceTarget *)target;
- (void)removeTarget:(PerformanceTarget *)target;
- (void)start;
- (void)stop;
@end
