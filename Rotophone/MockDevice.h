//
//  MockDevice.h
//  Rotophone
//
//  Created by z on 6/6/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Event.h"

@interface DeviceProviderSelector : NSObject<DeviceProvider>

@property (retain) NSObject<DeviceProvider>* deviceProvider;
@end

@interface MockDevice : NSObject<Device, RotoEventSource, RotoCommandWriter, DeviceProvider>

@end


