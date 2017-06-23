//
//  RandomPerformMode.h
//  Rotophone
//
//  Created by z on 6/23/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PerformMode.h"

@interface WaitPerformMode : PerformMode {
    NSTimeInterval _waitInterval;
}
@end

@interface RandomPerformMode : PerformMode {
    int _maxSteps;
    int _step;
}

@end



