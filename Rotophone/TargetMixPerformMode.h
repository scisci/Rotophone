//
//  TargetPerformMode.h
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PerformMode.h"

@interface TargetMixPerformMode : PerformMode {
    int _numTargets;
    int _baseTargetIndex;
    int _satelliteTargetIndex;
    int _currentTargetIndex;
    int _maxRepeats;
    int _repeatCount;
    float _currentTargetPosition;
    BOOL _targetInvalid;
    BOOL _scheduledNextStep;
    NSArray *_targets;
}

@end

