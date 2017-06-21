//
//  MicrophonePerformer.m
//  Rotophone
//
//  Created by z on 6/19/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MicrophonePerformer.h"

@implementation PerformanceTarget

@end

@interface MicrophonePerformer () {
    NSTimer* _nextTimer;
    NSArray* _targets;
    int _nextTarget;
}

@end


@implementation MicrophonePerformer
@synthesize microphone = _microphone;

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

- (NSObject<MicrophoneProxy> *)microphone {
    return _microphone;
}

- (void)start {
    
    
    [self moveToPosition:nil];
    
}

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


- (void)stop {
    if (_nextTimer != nil) {
        [_nextTimer invalidate];
        _nextTimer = nil;
    }
}

- (void)dealloc {
    self.microphone = nil;
}
@end
