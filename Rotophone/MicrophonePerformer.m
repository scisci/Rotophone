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
    //return [[TargetScanPerformMode alloc] initWithPerformer:self];
    float p = (float)rand() / RAND_MAX;
    
    NSLog(@"choosing perform mode, probability %f", p);
    
    if (p < 0.2) { // 20 %
        return [[RandomPerformMode alloc] initWithPerformer:self];
    } else if (p < 0.7) { // 50 %
        return [[TargetScanPerformMode alloc] initWithPerformer:self];
    } else { // 30 %
        return [[TargetMixPerformMode alloc] initWithPerformer:self];
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
    
    NSLog(@"ending old mode");
    if (_mode != nil) {
        [_mode end];
    }
    
    _mode = mode;
    
    if (_mode != nil) {
        NSLog(@"starting next mode");
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
