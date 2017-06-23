//
//  PerformMode.m
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "PerformMode.h"

#import "MicrophonePerformer.h"

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

- (void)updatePosition:(float)position andVelocity:(double)velocity andValid:(BOOL)valid {
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
