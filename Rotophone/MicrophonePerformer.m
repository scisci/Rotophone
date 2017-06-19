//
//  MicrophonePerformer.m
//  Rotophone
//
//  Created by z on 6/19/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MicrophonePerformer.h"

@interface MicrophonePerformer () {
    NSTimer* _nextTimer;
}

@end


@implementation MicrophonePerformer
@synthesize microphone = _microphone;

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
