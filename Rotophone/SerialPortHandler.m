//
//  SerialPortHandler.m
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SerialPortHandler.h"

@interface SerialPortHandler ()
{
    ORSSerialPort* _selectedPort;
}
@end

@implementation SerialPortHandler


- (void)setSelectedPort:(ORSSerialPort *)selectedPort {
    if (_selectedPort != nil) {
        NSLog(@"Disconnecting from serial port");
        _selectedPort.delegate = nil;
    }
    
    _selectedPort = selectedPort;
    if (_selectedPort != nil) {
        NSLog(@"Connecting to serial port");
        _selectedPort.delegate = self;
    }
}

- (ORSSerialPort *) selectedPort {
    return _selectedPort;
}
/**
 *  Called when a serial port is removed from the system, e.g. the user unplugs
 *  the USB to serial adapter for the port.
 *
 *	In this method, you should discard any strong references you have maintained for the
 *  passed in `serialPort` object. The behavior of `ORSSerialPort` instances whose underlying
 *  serial port has been removed from the system is undefined.
 *
 *  @param serialPort The `ORSSerialPort` instance representing the port that was removed.
 */
- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort {
    NSLog(@"Serial port removed");
    self.selectedPort = nil;
}

@end
