//
//  SimulationComposition.h
//  Rotophone
//
//  Created by z on 11/27/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SimulationCompositionDelegate

- (void)sendMidiData:(const unsigned char *)data ofSize:(size_t)dataSize;

@end

@interface SimulationComposition : NSObject

- (instancetype)initWithDelegate:(id<SimulationCompositionDelegate>)delegate andFreqs:(NSArray *)freqs;
- (void)loadMidiFile:(NSString *)path;
- (void)updatePosition:(double)position andVelocity:(double)velocity andValid:(bool)velocityValid;
- (void)refresh;
@end

NS_ASSUME_NONNULL_END
