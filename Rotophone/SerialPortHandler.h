//
//  SerialPortHandler.h
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORSSerialPort.h"

@interface SerialPortHandler : NSObject<ORSSerialPortDelegate>
@property (retain) ORSSerialPort* selectedPort;
@end
