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

@interface ConcreteUpdatePosEvent : NSObject<UpdatePosEvent> {
    double _timestamp;
    unsigned char _rotoID;
    float _position;
}

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID andPosition:(float)position;

@end

@implementation ConcreteUpdatePosEvent

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID andPosition:(float)position {
    if (self = [super init]) {
        _timestamp = timestamp;
        _rotoID = rotoID;
        _position = position;
    }
    return self;
}

- (double)timestamp {
    return _timestamp;
}

- (int) rotoID {
    return _rotoID;
}

- (float) position {
    return _position;
}

- (void)accept:(id<RotoEventVisitor>)visitor {
    if ([visitor respondsToSelector:@selector(visitUpdatePosEvent:)]) {
        [visitor visitUpdatePosEvent:self];
    }
}

@end


@interface ConcreteDataEvent : NSObject<DataEvent> {
    double _timestamp;
    unsigned char _rotoID;
    NSData* _data;
    TxEvent _type;
}

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID Type:(TxEvent)type andData:(NSData *)data;

@end

@implementation ConcreteDataEvent
- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID Type:(TxEvent)type andData:(NSData *)data {
    if (self = [super init]) {
        _timestamp = timestamp;
        _rotoID = rotoID;
        _data = data;
        _type = type;
    }
    return self;
}

- (double)timestamp {
    return _timestamp;
}

- (int) rotoID {
    return _rotoID;
}

- (NSData *) data {
    return _data;
}

- (TxEvent) eventType {
    return _type;
}


- (void)accept:(id<RotoEventVisitor>)visitor {
    if ([visitor respondsToSelector:@selector(visitSaveEvent:)]) {
        [visitor visitSaveEvent:self];
    }
}
@end


@interface ConcreteHandshakeEvent : NSObject<HandshakeEvent> {
    double _timestamp;
    unsigned char _rotoID;
    int _handshakeID;
    ModeType _mode;
}

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID HandshakeID:(int)handshakeID Mode:(ModeType)mode;

@end

@implementation ConcreteHandshakeEvent

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID HandshakeID:(int)handshakeID Mode:(ModeType)mode {
    if (self = [super init]) {
        _timestamp = timestamp;
        _rotoID = rotoID;
        _handshakeID = handshakeID;
        _mode = mode;
    }
    return self;
}

- (double)timestamp {
    return _timestamp;
}

- (int) rotoID {
    return _rotoID;
}

- (int) handshakeID {
    return _handshakeID;
}

- (ModeType) mode {
    return _mode;
}

- (void)accept:(id<RotoEventVisitor>)visitor {
    if ([visitor respondsToSelector:@selector(visitHandshakeEvent:)]) {
        [visitor visitHandshakeEvent:self];
    }
}

@end



@interface ConcreteUpdateModeEvent : NSObject<UpdateModeEvent> {
    double _timestamp;
    unsigned char _rotoID;
    ModeType _mode;
}

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID Mode:(ModeType)mode;

@end

@implementation ConcreteUpdateModeEvent

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID Mode:(ModeType)mode {
    if (self = [super init]) {
        _timestamp = timestamp;
        _rotoID = rotoID;
        _mode = mode;
    }
    return self;
}

- (double)timestamp {
    return _timestamp;
}

- (int) rotoID {
    return _rotoID;
}

- (ModeType) mode {
    return _mode;
}

- (void)accept:(id<RotoEventVisitor>)visitor {
    if ([visitor respondsToSelector:@selector(visitUpdateModeEvent:)]) {
        [visitor visitUpdateModeEvent:self];
    }
}

@end





@interface ConcreteErrorEvent : NSObject<ErrorEvent> {
    double _timestamp;
    unsigned char _rotoID;
    ErrCode _errorCode;
}

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID ErrorCode:(ErrCode)errorCode;

@end

@implementation ConcreteErrorEvent

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID ErrorCode:(ErrCode)errorCode {
    if (self = [super init]) {
        _timestamp = timestamp;
        _rotoID = rotoID;
        _errorCode = errorCode;
    }
    return self;
}

- (double)timestamp {
    return _timestamp;
}

- (int) rotoID {
    return _rotoID;
}

- (ErrCode) errorCode {
    return _errorCode;
}

- (void)accept:(id<RotoEventVisitor>)visitor {
    if ([visitor respondsToSelector:@selector(visitErrorEvent:)]) {
        [visitor visitErrorEvent:self];
    }
}

@end





@interface ConcreteGenericEvent : NSObject<GenericEvent> {
    double _timestamp;
    unsigned char _rotoID;
    TxEvent _eventType;
}

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID EventType:(TxEvent)eventType;

@end

@implementation ConcreteGenericEvent

- (id)initWithTimestamp:(double)timestamp rotoID:(int)rotoID EventType:(TxEvent)eventType {
    if (self = [super init]) {
        _timestamp = timestamp;
        _rotoID = rotoID;
        _eventType = eventType;
    }
    return self;
}

- (double)timestamp {
    return _timestamp;
}

- (int) rotoID {
    return _rotoID;
}

- (TxEvent) eventType {
    return _eventType;
}

- (void)accept:(id<RotoEventVisitor>)visitor {
    if (_eventType == kHeartBeatEvent && [visitor respondsToSelector:@selector(visitHandshakeEvent:)]) {
        [visitor visitHeartbeatEvent:self];
    }
}

@end



@implementation SerialPortCommandWriter

- (void)start:(RxCmd)command {
    _bufferPos = 0;
    _buffer[_bufferPos++] = kSerialHeader;
    _buffer[_bufferPos++] = command;
}

- (void)writeByte:(unsigned char)value {
    _buffer[_bufferPos++] = value;
}

- (void)writeShort:(int)value {
    _buffer[_bufferPos++] = value >> 8;
    _buffer[_bufferPos++] = value & 0xFF;
}

- (void)writeData:(NSData *)data {
    unsigned char* bytes = (unsigned char *)data.bytes;
    for (int i = 0; i < data.length; i++) {
        _buffer[_bufferPos++] = bytes[i];
    }
}

- (void)send {
    _buffer[_bufferPos++] = kSerialTrailer;
    
    NSData* data = [NSData dataWithBytes:&_buffer length:_bufferPos];
    
    _bufferPos = 0;
    
    if (_delegate != nil) {
        [_delegate sendData:data];
    }
}

- (void)setPosition:(float)position {
    // Convert it to a 16-bit integer
    int pos = position * 0xFFFF;
    if (pos < 0) {
        pos = 0;
    } else if (pos >= 0xFFFF) {
        pos = 0xFFFF - 1;
    }
    
    [self start:kSetPosCmd];
    [self writeShort:pos];
    [self send];
}

- (void)setMode:(ModeType)mode {
    [self start:kSetModeCmd];
    [self writeByte:mode];
    [self send];
}

- (void)sendHandshake:(unsigned char)handshakeID {
    [self start:kHandshakeCmd];
    [self writeByte:handshakeID];
    [self send];
}

- (void)setZero {
    [self start:kZeroCmd];
    [self send];
}

- (void)loadData:(NSData *)data {
    [self start:kLoadCmd];
    [self writeByte:data.length];
    [self writeData:data];
    [self send];
}

- (void)saveData {
    [self start:kSaveCmd];
    [self send];
}

@end




static int parserStatus(uint16_t expected, uint8_t *buf, uint16_t size) {
    if (size == expected + 1) {
        if (buf[expected] != kSerialTrailer) {
            return -1;
        }
        
        return 0; // Done
    }
    
    return expected + 1 - size;
}


@interface SerialPortHandler ()
{
    ORSSerialPort* _selectedPort;
    int _cmdBufferPos;
    unsigned char _cmdBuffer[64];
    bool _first;
    
}

@end

@implementation SerialPortHandler

- (id)init {
    if (self = [super init]) {
        self.commandWriter = [[SerialPortCommandWriter alloc] init];
        self.eventStream = [[RotoEventStream alloc] init];
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
        _first = true;
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
    _commandWriter.delegate = nil;
    self.selectedPort = nil;
}

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort {
    _commandWriter.delegate = self;
}



- (void)sendData:(NSData *)data {
    [_selectedPort sendData:data];
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    unsigned char *bytes = (unsigned char *)data.bytes;
    for (int i = 0; i < data.length; i++) {
        [self parseByte: bytes[i]];
    }
    
    if (_rawStreamHandler != nil && data.length > 0) {
        [_rawStreamHandler handleRawData:data];
    }
}
/*
- (id<CommandParser>)createCommandParser:(TxEvent)cmd {
    switch (cmd) {
        case kCurPosEvent:
            if (_updatePosCommandParser == nil) {
                self.updatePosCommandParser = [[UpdatePosCommandParser alloc] init];
            }
            
            return _updatePosCommandParser;
        case kHandshakeEvent:
            if (_handshakeCommandParser == nil) {
                self.handshakeCommandParser = [[HandshakeCommandParser alloc] init];
            }
            
            return _handshakeCommandParser;
        case kHeartBeatEvent:
            if (_genericCommandParser == nil) {
                self.genericCommandParser = [[GenericCommandParser alloc] init];
            }
            _genericCommandParser->eventType = cmd;
            return _genericCommandParser;
        default:
            return nil;
    }
}
*/
- (double)createTimestamp {
    return [[NSDate date] timeIntervalSince1970];
}

- (int)parseCommandBuffer {
    unsigned char* bytes = &_cmdBuffer[2];
    size_t size = _cmdBufferPos - 2;
    TxEvent cmdType = _cmdBuffer[1];
    int status = -1;
    switch (cmdType) {
        case kCurPosEvent:
            if ((status = parserStatus(2, bytes, size)) == 0) {
                float pos = 2.0 * M_PI *(float)(((short)bytes[0]) << 8 | bytes[1]) / 1024;
                [_eventStream handleEvent:[[ConcreteUpdatePosEvent alloc] initWithTimestamp:[self createTimestamp] rotoID:0 andPosition:pos]];
            }
            break;
        case kCurModeEvent:
            if ((status = parserStatus(1, bytes, size)) == 0) {
                ModeType mode = bytes[0];
                [_eventStream handleEvent:[[ConcreteUpdateModeEvent alloc] initWithTimestamp:[self createTimestamp] rotoID:0 Mode:mode]];
            }
        case kHandshakeEvent:
            if ((status = parserStatus(2, bytes, size)) == 0) {
                int handshakeID = bytes[0];
                ModeType mode = bytes[1];
                [_eventStream handleEvent:[[ConcreteHandshakeEvent alloc] initWithTimestamp:[self createTimestamp] rotoID:0 HandshakeID:handshakeID Mode:mode]];
            }
            break;
        case kHeartBeatEvent:
            if ((status = parserStatus(0, bytes, size)) == 0) {
                [_eventStream handleEvent:[[ConcreteGenericEvent alloc] initWithTimestamp:[self createTimestamp] rotoID:0 EventType:cmdType]];
            }
            break;
        case kErrEvent:
            if ((status = parserStatus(2, bytes, size)) == 0) {
                ErrCode errorCode = (int)bytes[0] << 8 | bytes[1];
                [_eventStream handleEvent:[[ConcreteErrorEvent alloc] initWithTimestamp:[self createTimestamp] rotoID:0 ErrorCode:errorCode]];
            }
            break;
        case kSaveEvent:
            if (size == 0) {
                return 1;
            }
            if ((status = parserStatus(bytes[0], bytes, size)) == 0) {
                if (size < 4) {
                    return -1;
                }
                // Extract the data which is from byte 1 to before the trailer
                // The last byte is a checksum
                uint8_t checksum = 0;
                for (int i = 1; i < size - 2; i++) {
                    checksum += bytes[i];
                }
                if (bytes[size - 2] != checksum) {
                    return -1;
                }
                
                NSData *data = [[NSData alloc] initWithBytes:&bytes[1] length:size - 2];
                [_eventStream handleEvent:[[ConcreteDataEvent alloc] initWithTimestamp:[self createTimestamp] rotoID:0 Type:cmdType andData:data]];
            }
            break;
        

    }
    return status;
}

- (void)parseByte:(unsigned char)b {
    if (_cmdBufferPos > 1) {
        _cmdBuffer[_cmdBufferPos++] = b;
        int status = [self parseCommandBuffer];
        if (status <= 0) {
            // Done or error
            _cmdBufferPos = 0;
            if (status == 0) {
                return;
            }
        }
    }
    
    if (_cmdBufferPos == 1) {
        _cmdBuffer[_cmdBufferPos++] = b;
        int status = [self parseCommandBuffer];
        if (status < 0) {
            _cmdBufferPos = 0;
        }
    }
    
    if (_cmdBufferPos == 0) {
        if (b == kSerialHeader) {
            _cmdBuffer[_cmdBufferPos++] = b;
        }
    }
}

@end
