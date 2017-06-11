//
//  MicrophoneShapeAdapter.h
//  Rotophone
//
//  Created by z on 5/30/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#ifndef MicrophoneShapeAdapter_h
#define MicrophoneShapeAdapter_h

#import "Shape.h"
#import "MicrophoneController.h"


@interface MicrophoneShapeAdapter : NSObject<MicrophoneShape> {
    
}

@property (retain) id<MicrophoneProxy> proxy;

- (id)initWithProxy:(id<MicrophoneProxy>)proxy;

@end


#endif /* MicrophoneShapeAdapter_h */
