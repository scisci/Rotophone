//
//  PerformMode.h
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MicrophonePerformer;

@interface PerformMode : NSObject{
    NSTimer* _scheduler;
    NSDate* _startTime;
}

@property (unsafe_unretained) MicrophonePerformer* performer;

- (id)initWithPerformer:(MicrophonePerformer*)performer;
- (void)begin; // called by performer
- (void)end;
- (void)updatePosition:(float)position andVelocity:(double)velocity andValid:(BOOL)valid;
- (void)scheduleTimer:(NSTimeInterval)interval; // Schedules a callback
- (void)clearTimer;
- (void)handleTimer:(id)sender; // Called
- (void)complete; // Calls performer when mode is done.
- (NSTimeInterval)elapsedTime;
@end


