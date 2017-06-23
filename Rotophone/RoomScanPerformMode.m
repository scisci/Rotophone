//
//  RoomScanPerformMode.m
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "RoomScanPerformMode.h"
#import "MicrophonePerformer.h"

@implementation RoomScanPerformMode


- (void)begin {
    [super begin];
    // Choose any random position
    _initialTarget = ((float)rand() / RAND_MAX) * 2 * M_PI;
    _direction = 0.0;
    _targetSpeed = 1.0 / 2 * M_PI;
    _scheduledComplete = NO;
    _maxTime = 3.0 + ((float)rand() / RAND_MAX) * 20.0;
    _speedParam = 0.1 + ((float)rand() / RAND_MAX) * .85;
    
    [self moveToPosition:_initialTarget];
}

- (BOOL)completeIfNecessary {
    if (self.elapsedTime > 60.0) {
        [self complete];
        return YES;
    }
    
    return NO;
}


- (void)updatePosition:(float)position andVelocity:(double)velocity andValid:(BOOL)valid {
    if ([self completeIfNecessary]) {
        return;
    }
    
    if (_scheduledComplete) {
        return;
    }

    float dist = _currentTargetPosition - position;
    if (dist > M_PI) {
        dist -= 2 * M_PI;
    } else if (dist < -M_PI) {
        dist += 2 * M_PI;
    }
    
    if (fabs(dist) > 0) {
        _direction = fabs(dist) / dist;
    }
    
    // If its within 90 degrees of the target, then schedule it
    if (fabs(dist) < M_PI * 0.5 && _direction != 0) {
        NSTimeInterval elapsed = self.elapsedTime;
        if (elapsed > _maxTime) {
            if (fabs(dist) < 0.01) {
                _scheduledComplete = YES;
                [self scheduleTimer:1.5 + ((float)rand() / RAND_MAX) * 5.0];
            }
            return;
        }
        
        // Choose a new point
        [self moveToPosition:position + M_PI * _speedParam * _direction];
    }
    
   if (valid && velocity == 0) {
        // Not moving, maybe didn't receive last command
        [self moveToPosition:_currentTargetPosition];
    }
}

- (void)moveToPosition:(float)position {
    while (position > 2 * M_PI) {
        position -= 2 * M_PI;
    }
    
    while (position < 0) {
        position += 2 * M_PI;
    }
    
    _currentTargetPosition = position;
    [self.performer.microphone setRotoTarget:position];
}

- (void)handleTimer:(id)sender {
    if (_scheduledComplete) {
        _scheduledComplete = NO;
        [self complete];
        return;
    }
}

@end
