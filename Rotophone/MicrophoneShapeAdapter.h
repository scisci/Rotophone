//
//  MicrophoneShapeAdapter.h
//  Rotophone
//
//  Created by z on 5/30/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#ifndef MicrophoneShapeAdapter_h
#define MicrophoneShapeAdapter_h

#import "Entities.h"
#import "Shape.h"


@interface MicrophoneShapeAdapter : NSObject<MicrophoneShape> {
    
}

@property (retain) MicrophoneEntity* model;

- (id)initWithModel:(MicrophoneEntity*)model;

@end


#endif /* MicrophoneShapeAdapter_h */
