//
//  TargetPerformMode.m
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "TargetMixPerformMode.h"
#import "MicrophonePerformer.h"

@implementation TargetMixPerformMode

- (void)begin {
    [super begin];
    
    int maxTargets = (int)self.performer.targets.count;
    
    if (maxTargets < 2) {
        // Can't work
        [self complete];
    } else {
        if (maxTargets > 4) {
            maxTargets = 4;
        }
        _numTargets = 2 + (maxTargets == 2 ? 0 : (rand() % (maxTargets - 1)));
        
        int totalMotions = _numTargets * (_numTargets - 1);
        
        _maxRepeats = totalMotions > 10 ? 0 : rand() % (10 / totalMotions);
        _repeatCount = 0;
        
        // Copy in
        NSMutableArray* targets = [NSMutableArray arrayWithArray:self.performer.targets];
        NSMutableArray* results = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < _numTargets; i++) {
            PerformanceTarget* object = [targets objectAtIndex:rand() % targets.count];
            [targets removeObject:object];
            [results addObject:object];
        }
        
        _targetInvalid = NO;
        _scheduledNextStep = NO;
        _targets = [NSArray arrayWithArray:results];
        _baseTargetIndex = 0;
        _satelliteTargetIndex = 1;
        _currentTargetIndex = -1;
        [self step];
    }
}

- (void)step {
    
    if ([self completeIfNecessary]) {
        return;
    }
    
    [self clearTimer];
    _targetInvalid = NO;
    _scheduledNextStep = NO;
    
    if (_currentTargetIndex != _baseTargetIndex) {
        // NSLog(@"move to base %d (rep %d)", _baseTargetIndex, _repeatCount);
        [self moveToTarget:_baseTargetIndex];
        return;
    }
    
    if (_satelliteTargetIndex >= _numTargets) {
        if (++_baseTargetIndex >= _numTargets) {
            if (_repeatCount++ < _maxRepeats) {
                // reset
                _baseTargetIndex = 0;
                _satelliteTargetIndex = 1;
                [self step];
            } else {
                [self complete];
            }
            return;
        } else {
            _satelliteTargetIndex = _baseTargetIndex + 1;
            [self step];
            return;
        }
    }
    
    //NSLog(@"move to satellite %d", _satelliteTargetIndex);
    [self moveToTarget:_satelliteTargetIndex++];
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
    
    if (fabsf(dist) < 0.05) {
        _scheduledNextStep = YES;
        [self scheduleTimer:0.0 + ((float)rand() / RAND_MAX) * 3.0];
    } else if (valid && velocity == 0) {
        // Not moving, maybe didn't receive last command
        [self moveToPosition:_currentTargetPosition];
    }
}

- (void)moveToTarget:(int)targetIndex {
    _currentTargetIndex = targetIndex;
    
    // Choose a value between min/max
    
    PerformanceTarget* target = [_targets objectAtIndex:targetIndex];
    
    // Choose a random value inside the target
    float dist = (target.angleMax - target.angleMin);
    
    if (dist <= 0) {
        _targetInvalid = YES;
        [self scheduleTimer:0.1];
        return;
    } else {
        _targetInvalid = NO;
    }
    float boundary = 0.25;
    float angle = target.angleMin + dist * boundary + dist * ((float)rand() / RAND_MAX) * (1 - boundary * 2);
    
    [self moveToPosition:angle];
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

- (void)clearTimer {
    [super clearTimer];
}

- (void)handleTimer:(id)sender {
    if (_targetInvalid) {
        _targetInvalid = NO;
        [self moveToTarget:_currentTargetIndex];
        return;
    }
    
    if (_scheduledNextStep) {
        _scheduledNextStep = NO;
        [self step];
    }
}

@end
