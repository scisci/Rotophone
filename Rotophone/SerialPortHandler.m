//
//  SerialPortHandler.m
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SerialPortHandler.h"
#import "ORSSerialPortManager.h"
#import "Event.h"
#import "SerialPortDevice.h"

@interface SerialPortHandler ()
{
    ORSSerialPort* _selectedPort;
    
}

@end

@implementation SerialPortHandler

- (id)init {
    if (self = [super init]) {
    }
    return self;
}



- (void)selectPortByPath:(NSString *)path {
    ORSSerialPortManager* manager = [ORSSerialPortManager sharedSerialPortManager];
    
    for (ORSSerialPort *port in manager.availablePorts) {
        if ([port.path isEqualToString:path]) {
            self.selectedPort = port;
            return;
        }
    }
}



- (void)setSelectedPort:(ORSSerialPort *)selectedPort {
    if (selectedPort == _selectedPort) {
        return;
    }

    if (_selectedPort != nil) {
        NSLog(@"Disconnecting from serial port");
        _selectedPort.delegate = nil;
        [_selectedPort close];
    }
    
    _selectedPort = selectedPort;
    if (_selectedPort != nil) {
        NSLog(@"Connecting to serial port");
        _selectedPort.baudRate = @115200;
        _selectedPort.parity = ORSSerialPortParityNone;
        _selectedPort.numberOfStopBits = 1;
        _selectedPort.usesRTSCTSFlowControl = NO;
        _selectedPort.delegate = self;
        [_selectedPort open];
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
    self.device = nil;
    self.selectedPort = nil;
}

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort {
    self.device = [[SerialPortDevice alloc] initWithDelegate:self];
}



- (void)sendData:(NSData *)data {
    [_selectedPort sendData:data];
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    if (_device != nil) {
        [_device didReceiveData:data];
    }
    
    
    if (_rawStreamHandler != nil && data.length > 0) {
        [_rawStreamHandler handleRawData:data];
    }
}

@end
