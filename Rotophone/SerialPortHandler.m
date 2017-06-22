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
    ORSSerialPort* _retryPort;
    int _retryCount;
    NSTimer* _openTimeout;
    NSTimer* _retryTimeout;
    
}

@end

@implementation SerialPortHandler

- (id)init {
    if (self = [super init]) {
        _retryCount = 0;
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


- (void)reload {
    if (_selectedPort == nil) {
        return;
    }
    
    if (_retryTimeout != nil) {
        [_retryTimeout invalidate];
        _retryTimeout = nil;
    }
    
    // Disconnect and reconnect
    if (_retryPort == _selectedPort) {
        _retryCount++;
    } else {
        _retryCount = 1;
    }
    
    _retryPort = _selectedPort;
    self.selectedPort = nil;
    
    double duration = 5.0 * _retryCount;
    NSLog(@"Will retry port for %d time in %f seconds...", _retryCount, duration);
    
    _retryTimeout = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:duration] interval:duration target:self selector:@selector(handleRetryTimeout:) userInfo:nil repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:_retryTimeout forMode:NSRunLoopCommonModes];

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
    
    if (_openTimeout != nil) {
        [_openTimeout invalidate];
        _openTimeout = nil;
    }
    
    if (_retryTimeout != nil) {
        [_retryTimeout invalidate];
        _retryTimeout = nil;
    }
    
    _selectedPort = selectedPort;
    if (_selectedPort != nil) {
        NSLog(@"Connecting to serial port");
        _selectedPort.baudRate = @115200;
        _selectedPort.parity = ORSSerialPortParityNone;
        _selectedPort.numberOfStopBits = 1;
        _selectedPort.usesRTSCTSFlowControl = NO;
        _selectedPort.usesDTRDSRFlowControl = NO;
        _selectedPort.delegate = self;
        
        _openTimeout = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:15.0] interval:15.0 target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
        
        [[NSRunLoop currentRunLoop] addTimer:_openTimeout forMode:NSRunLoopCommonModes];
        
        [_selectedPort open];
    }
}

- (void)handleTimeout:(id)sender {
    if (_selectedPort != nil) {
        NSLog(@"port open timed out!");
        if (!_selectedPort.isOpen) {
            NSLog(@"Port is not open");
            [self reload];
        } else {
            NSLog(@"But port is open?!");
        }
    }
}

- (void)handleRetryTimeout:(id)sender {
    
    NSLog(@"retrying connection");
    
    if (_selectedPort == nil && _retryPort != nil) {
        self.selectedPort = _retryPort;
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
    // This will call close which will also nullify device
    self.selectedPort = nil;
    _retryPort = nil;
}

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort {
    if (_openTimeout != nil) {
        [_openTimeout invalidate];
        _openTimeout = nil;
    }
    
    NSLog(@"Connected to serialport.");
    
    _retryPort = nil;
    self.device = [[SerialPortDevice alloc] initWithDelegate:self];
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort {
    if (_openTimeout != nil) {
        [_openTimeout invalidate];
        _openTimeout = nil;
    }
    
    self.device = nil;
}

- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error {
    NSLog(@"Serial port error %@.", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
    
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
