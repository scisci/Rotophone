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

@protocol RawStreamHandler<NSObject>
- (void)handleRawData:(NSData *)rawData;
@end

@protocol CommandWriter<NSObject>
- (void)setPosition:(float)position;
- (void)setMode:(ModeType)mode;
- (void)sendHandshake:(unsigned char)handshakeID;
- (void)setZero;
- (void)loadData:(NSData *)data;
- (void)saveData;
@end

@protocol CommandWriterDelegate
- (void)sendData:(NSData *)data;
@end

@interface SerialPortCommandWriter : NSObject<CommandWriter> {
    unsigned char _buffer[64];
    int _bufferPos;
}
@property (unsafe_unretained) id<CommandWriterDelegate> delegate;

- (void)start:(RxCmd)command;
- (void)writeByte:(unsigned char)value;
- (void)writeShort:(int)value;
- (void)send;

@end

@interface SerialPortHandler : NSObject<ORSSerialPortDelegate, CommandWriterDelegate>

@property (retain) ORSSerialPort* selectedPort;
@property (retain) SerialPortCommandWriter* commandWriter;
@property (retain) RotoEventStream* eventStream;
@property (retain) id<RawStreamHandler> rawStreamHandler;

- (void)selectPortByPath:(NSString *)path;
@end
