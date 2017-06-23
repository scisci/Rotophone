//
//  RoomScanPerformMode.h
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "PerformMode.h"

@interface RoomScanPerformMode : PerformMode {
    float _initialTarget;
    float _targetSpeed;
    float _direction;
    float _currentTargetPosition;
    BOOL _scheduledComplete;
    double _maxTime;
    float _speedParam;
}

@end
