//
//  RandomPerformMode.m
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "RandomPerformMode.h"
#import "MicrophonePerformer.h"

@implementation RandomPerformMode

- (void)begin {
    [super begin];
    
    _maxSteps = 1 + rand() % 8;
    _step = 0;
    
    [self move];
}

- (float)chooseNextValue {
    return ((float)rand() / RAND_MAX) * 2 * M_PI;
}

- (void)move {
    if (_step++ >= _maxSteps || [self elapsedTime] > 20.0) {
        [self complete];
    } else {
        [self.performer.microphone setRotoTarget:[self chooseNextValue]];
        float nextTime = 0.5 + ((float)rand() / RAND_MAX) * 5.0;
        [self scheduleTimer:nextTime];
    }
}

- (void)handleTimer:(id)sender {
    [self move];
}

@end
