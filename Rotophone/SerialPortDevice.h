//
//  SerialPortDevice.h
//  Rotophone
//
//  Created by z on 6/5/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Event.h"


@interface SerialPortDevice : NSObject<Device>


- (id)initWithDelegate:(id<RotoCommandWriterDelegate>)delegate;
- (void)didReceiveData:(NSData *)data;

@end
