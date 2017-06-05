//
//  SerialPortHandler.h
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORSSerialPort.h"
#import "Protocol.h"
#import "Event.h"
#import "SerialPortDevice.h"


@interface SerialPortHandler : NSObject<DeviceProvider, ORSSerialPortDelegate, RotoCommandWriterDelegate>

@property (retain) ORSSerialPort* selectedPort;
@property (retain) SerialPortDevice* device;
@property (retain) id<RawStreamHandler> rawStreamHandler;


- (void)selectPortByPath:(NSString *)path;
@end
