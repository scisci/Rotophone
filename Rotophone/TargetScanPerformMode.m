//
//  TargetScanPerformMode.m
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "TargetScanPerformMode.h"
#import "MicrophonePerformer.h"

@implementation TargetScanPerformMode


- (void)begin {
    [super begin];
    
    // Choose a random target
    _targetInvalid = NO;
    _scheduledNextStep = NO;
    _maxReps = 2 + rand() % 12;
    _reps = 0;
    [self initTarget];
}

- (void)initTarget {
    int maxTargets = (int)self.performer.targets.count;
    
    if (maxTargets == 0) {
        // Can't work
        [self complete];
        return;
    } else {
        PerformanceTarget *target = [self.performer.targets objectAtIndex:rand() % maxTargets];
        
        // Choose a random value inside the target
        float dist = (target.angleMax - target.angleMin);
        
        if (dist <= 0) {
            _targetInvalid = YES;
            [self scheduleTimer:0.1];
            return;
        } else {
            _targetInvalid = NO;
        }
        
        float angle = target.angleMin + dist * ((float)rand() / RAND_MAX);
        _targetPoint = angle;
        
        float sweepSize = .1 + .3 * ((float)rand() / RAND_MAX);
        _targetMin = angle - sweepSize;
        _targetMax = angle + sweepSize;
        
        _scanPos = 0;
        _rightToLeft = rand() % 2; // Start on 0 or 1
        
        if (_targetMin < target.angleMin - 0.08) {
            _targetMin = target.angleMin - 0.08;
        }
        
        if (_targetMax > target.angleMax + 0.08) {
            _targetMax = target.angleMax + 0.08;
        }
        
        [self step];
        
    }
}

- (void)step {
    
    if ([self completeIfNecessary]) {
        return;
    }
    
    if (_reps++ >= _maxReps) {
        [self complete];
        return;
    }
    
    if (_scanPos == 0) {
        // Move left
        _scanPos = 1;
        if (!_rightToLeft) {
            [self moveToPosition:_targetMin];
        } else {
            [self moveToPosition:_targetMax];
        }
    } else if (_scanPos == 1) {
        _scanPos = 2;
        if (!_rightToLeft) {
            [self moveToPosition:_targetMax];
        } else {
            [self moveToPosition:_targetMin];
        }
    } else if (_scanPos == 2){
        // Scale down the sweep angle
        _targetMin += (_targetPoint - _targetMin) * 0.5;
        _targetMax += (_targetPoint - _targetMax) * 0.5;
 
        if (_targetMax - _targetMin < 0.03) {
            _scanPos = 3;
            [self moveToPosition:_targetPoint];
        } else {
            _scanPos = 0;
            [self step];
        }
    } else {
        [self complete];
        return;
    }
}

- (BOOL)completeIfNecessary {
    if (self.elapsedTime > 20.0) {
        [self complete];
        return YES;
    }
    
    return NO;
}

- (void)updatePosition:(float)position andVelocity:(double)velocity andValid:(BOOL)valid {
    if ([self completeIfNecessary]) {
        return;
    }
    
    if (_targetInvalid) {
        return;
    }
    
    if (_scheduledNextStep) {
        return;
    }
    
    float dist = _currentTargetPosition - position;
    if (dist > M_PI) {
        dist -= 2 * M_PI;
    } else if (dist < -M_PI) {
        dist += 2 * M_PI;
    }
    
    if (fabsf(dist) < 0.02) {
        _scheduledNextStep = YES;
        [self scheduleTimer:_scanPos == 3 ? 3.0 + ((float)rand() / RAND_MAX) : 0.01];
    } else if (valid && velocity == 0) {
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
    if (_targetInvalid) {
        _targetInvalid = NO;
        [self initTarget];
    }
    
    if (_scheduledNextStep) {
        _scheduledNextStep = NO;
        [self step];
    }
}


@end
