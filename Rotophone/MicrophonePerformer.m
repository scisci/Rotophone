//
//  MicrophonePerformer.m
//  Rotophone
//
//  Created by z on 6/19/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MicrophonePerformer.h"

@class PerformMode;

@interface MicrophonePerformer() {
    NSTimer* _nextTimer;
    NSArray* _targets;
    int _nextTarget;
}

@property (retain) PerformMode* mode;

- (void)endMode:(PerformMode *)mode;
@end

@interface PerformMode : NSObject{
    NSTimer* _scheduler;
    NSDate* _startTime;
}

@property (unsafe_unretained) MicrophonePerformer* performer;

- (id)initWithPerformer:(MicrophonePerformer*)performer;
- (void)begin; // called by performer
- (void)update; // called by performer on angle change
- (void)scheduleTimer:(NSTimeInterval)interval; // Schedules a callback
- (void)clearTimer;
- (void)handleTimer:(id)sender; // Called
- (void)complete; // Calls performer when mode is done.
- (NSTimeInterval)elapsedTime;
@end

@implementation PerformMode

- (id)initWithPerformer:(MicrophonePerformer *)performer {
    if (self = [super init]) {
        self.performer = performer;
    }
    return self;
}

- (void)begin {
    _startTime = [NSDate date];
}

- (void)end {
    [self clearTimer];
}

- (NSTimeInterval)elapsedTime {
    return -[_startTime timeIntervalSinceNow];
}

- (void)update {
    // Imp
}

- (void)clearTimer {
    if (_scheduler != nil) {
        [_scheduler invalidate];
        _scheduler = nil;
    }
}

- (void)scheduleTimer:(NSTimeInterval)interval {
    [self clearTimer];
    
    _scheduler = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:interval] interval:interval target:self selector:@selector(handleTimer:) userInfo:nil repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:_scheduler forMode:NSRunLoopCommonModes];
}

- (void)handleTimer:(id)sender {
    // Imp
}

- (void)complete {
    if (_performer == nil) {
        return;
    }
    
    [self clearTimer];
    
    [_performer endMode:self];
}

- (void)dealloc {
    [self clearTimer];
}

@end


@interface RandomPerformMode : PerformMode {
    int _maxSteps;
    int _step;
}

@end


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
    
    
    [self.performer.microphone setRotoTarget:[self chooseNextValue]];
    
    if (++_step >= _maxSteps || [self elapsedTime] > 20.0) {
        [self complete];
    } else {
        float nextTime = 0.1 + ((float)rand() / RAND_MAX) * 5.0;
        [self scheduleTimer:nextTime];
    }
}

- (void)handleTimer:(id)sender {
    [self move];
}

@end


@implementation PerformanceTarget

@end



@implementation MicrophonePerformer
@synthesize microphone = _microphone;
@synthesize mode = _mode;

- (id)init {
    if (self = [super init]) {
        _targets = [[NSArray alloc] init];
        _nextTarget = 0;
    }
    return self;
}

- (void)addTarget:(PerformanceTarget *)target {
    _targets = [_targets arrayByAddingObject:target];
}

- (void)removeTarget:(PerformanceTarget *)target {
    NSMutableArray *targets = [NSMutableArray arrayWithArray:_targets];
    [targets removeObject:target];
    _targets = [NSArray arrayWithArray:targets];
}

- (void)setMicrophone:(NSObject<MicrophoneProxy> *)microphone {
    if (_microphone != nil) {
        // remove observers
    }
    
    _microphone = microphone;
    
    if (_microphone != nil) {
        // add observers
    }
}

- (PerformMode *)chooseNextMode {
    return [[RandomPerformMode alloc] initWithPerformer:self];
}

- (void)endMode:(PerformMode *)mode {
    if (mode != _mode) {
        return;
    }
    // Choose a random mode
    
    self.mode = [self chooseNextMode];
    
    
}

- (PerformMode *)mode {
    return _mode;
}

- (void)setMode:(PerformMode *)mode {
    if (mode == _mode) {
        return;
    }
    
    if (_mode != nil) {
        [_mode end];
    }
    
    _mode = mode;
    
    if (_mode != nil) {
        [_mode begin];
    }
}

- (NSObject<MicrophoneProxy> *)microphone {
    return _microphone;
}

- (void)start {
    
    self.mode = [self chooseNextMode];
    
}
/*
- (float)chooseNextValue {
    if (_targets.count == 0) {
        return 0;
    }
    // Move to the center of the first target
    if (_nextTarget >= _targets.count) {
        _nextTarget = 0;
    }
    
    PerformanceTarget* target = [_targets objectAtIndex:_nextTarget++];

    float angle = (target.angleMin + target.angleMax) / 2;
    
    while (angle > 2 * M_PI) {
        angle -= 2 * M_PI;
    }
    
    while (angle < 0) {
        angle += 2 * M_PI;
    }
    
    return angle;
    
    
    float nextValue = ((float)rand() / RAND_MAX) * 2 * M_PI;
    return nextValue;
}

- (void)moveToPosition:(id)sender {
    if (_nextTimer != nil) {
        [_nextTimer invalidate];
        _nextTimer = nil;
    }
    
    
    
    [_microphone setRotoTarget:[self chooseNextValue]];
    
    float nextTime = 0.1 + ((float)rand() / RAND_MAX) * 5.0;
    _nextTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:nextTime] interval:0.0 target:self selector:@selector(moveToPosition:) userInfo:nil repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:_nextTimer forMode:NSRunLoopCommonModes];
}
*/

- (void)stop {
    self.mode = nil;
}

- (void)dealloc {
    self.mode = nil;
    self.microphone = nil;
}
@end
