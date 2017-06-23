//
//  MicrophonePerformer.m
//  Rotophone
//
//  Created by z on 6/19/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MicrophonePerformer.h"

#import "RandomPerformMode.h"
#import "TargetMixPerformMode.h"
#import "TargetScanPerformMode.h"
#import "RoomScanPerformMode.h"

@class PerformMode;

@interface MicrophonePerformer() {
    NSArray* _targets;
}

@property (retain) PerformMode* mode;


@end










@implementation PerformanceTarget

@end



@implementation MicrophonePerformer
@synthesize microphone = _microphone;
@synthesize mode = _mode;

- (id)init {
    if (self = [super init]) {
        _targets = [[NSArray alloc] init];
    }
    return self;
}

- (NSArray *)targets {
    return _targets;
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
    float p = (float)rand() / RAND_MAX;
    
    NSLog(@"choosing perform mode, probability %f", p);
    
    if (p < 0.10) { // 10 %
        NSLog(@"random mode");
        return [[RandomPerformMode alloc] initWithPerformer:self];
    } else if (p < 0.20) { // 10 %
        NSLog(@"wait mode");
        return [[WaitPerformMode alloc] initWithPerformer:self];
    }else if (p < 0.55) { // 35 %
        NSLog(@"target scan mode");
        return [[TargetScanPerformMode alloc] initWithPerformer:self];
    } else if (p < 0.80){ // 25 %
        NSLog(@"target mix mode");
        return [[TargetMixPerformMode alloc] initWithPerformer:self];
    } else { // 20%
        NSLog(@"room scan mode");
        return [[RoomScanPerformMode alloc] initWithPerformer:self];
    }
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

- (void)updatePosition:(float)position andVelocity:(double)velocity andValid:(BOOL)valid {
    if (_mode != nil) {
        //
        [_mode updatePosition:position andVelocity:velocity andValid:valid];
    }
}


- (void)stop {
    self.mode = nil;
}

- (void)dealloc {
    self.mode = nil;
    self.microphone = nil;
}
@end
