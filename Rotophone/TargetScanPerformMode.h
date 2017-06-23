//
//  TargetScanPerformMode.h
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "PerformMode.h"

@interface TargetScanPerformMode : PerformMode {
    int _target;
    float _targetMin;
    float _targetPoint;
    float _targetMax;
    int _maxReps;
    int _reps;
    float _currentTargetPosition;
    int _scanPos;
    int _rightToLeft;
    BOOL _targetInvalid;
    BOOL _scheduledNextStep;
}

@end
