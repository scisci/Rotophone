//
//  SerialPortDevice.m
//  Rotophone
//
//  Created by z on 6/5/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SerialPortDevice.h"

static void *SelectedPortKVOContext = &SelectedPortKVOContext;



@interface SerialPortCommandWriter : NSObject<RotoCommandWriter> {
    unsigned char _buffer[64];
    int _bufferPos;
}
@property (unsafe_unretained) id<RotoCommandWriterDelegate> delegate;

- (void)start:(RxCmd)command;
- (void)writeByte:(unsigned char)value;
- (void)writeShort:(int)value;
- (void)send;

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


@interface SerialPortDevice () {
    id<RotoCommandWriterDelegate> _delegate;
    SerialPortCommandWriter* _commandWriter;
    RotoEventStream* _eventStream;
    int _cmdBufferPos;
    unsigned char _cmdBuffer[64];

}
@end

@implementation SerialPortDevice

- (id)initWithDelegate:(id<RotoCommandWriterDelegate>)delegate {
    
    if (self = [super init]) {
        _delegate = delegate;
        _commandWriter = [[SerialPortCommandWriter alloc] init];
        _commandWriter.delegate = delegate;
        
        _eventStream = [[RotoEventStream alloc] init];
    }
    
    return self;

}

- (id<RotoCommandWriter>)deviceWriter {
    return _commandWriter;
}

- (id<RotoEventSource>)deviceReader {
    return _eventStream;
}


- (void)didReceiveData:(NSData *)data {
    unsigned char *bytes = (unsigned char *)data.bytes;
    for (int i = 0; i < data.length; i++) {
        [self parseByte: bytes[i]];
    }

}


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
