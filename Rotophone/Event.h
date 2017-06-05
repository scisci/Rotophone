//
//  Event.h
//  Rotophone
//
//  Created by z on 5/30/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#ifndef Event_h
#define Event_h

#import "Protocol.h"

@protocol RotoEventVisitor;

@protocol RotoEvent<NSObject>
    - (double)timestamp;
    - (int)rotoID;
    - (void)accept:(id<RotoEventVisitor>)visitor;
@end

@protocol HandshakeEvent<RotoEvent>
- (int)handshakeID;
- (ModeType)mode;
@end

@protocol GenericEvent<RotoEvent>
- (TxEvent)eventType;
@end


@protocol UpdatePosEvent<RotoEvent>
    - (float)position;
@end

@protocol UpdateModeEvent<RotoEvent>
- (ModeType)mode;
@end

@protocol ErrorEvent<RotoEvent>
- (ErrCode)errorCode;
@end

@protocol DataEvent<RotoEvent>
- (TxEvent)eventType;
- (NSData *)data;
@end

@protocol RotoEventVisitor<NSObject>
@optional
- (void)visitUpdatePosEvent:(id<UpdatePosEvent>)event;
- (void)visitHandshakeEvent:(id<HandshakeEvent>)event;
- (void)visitHeartbeatEvent:(id<GenericEvent>)event;
- (void)visitUpdateModeEvent:(id<UpdateModeEvent>)event;
- (void)visitErrorEvent:(id<ErrorEvent>)event;
- (void)visitSaveEvent:(id<DataEvent>)event;
@end


@protocol RotoEventHandler<NSObject>
    - (void)handleEvent:(id<RotoEvent>)event;
@end

@protocol RotoCommandWriter<NSObject>
- (void)setPosition:(float)position;
- (void)setMode:(ModeType)mode;
- (void)sendHandshake:(unsigned char)handshakeID;
- (void)setZero;
- (void)loadData:(NSData *)data;
- (void)saveData;
@end

@protocol RotoCommandWriterDelegate
- (void)sendData:(NSData *)data;
@end

@protocol RotoEventSource<NSObject>
- (void)addHandler:(id<RotoEventHandler>)handler;
- (void)removeHandler:(id<RotoEventHandler>)handler;
@end

@protocol RawStreamHandler<NSObject>
- (void)handleRawData:(NSData *)rawData;
@end


@protocol Device

@property (readonly) id<RotoCommandWriter> deviceWriter;
@property (readonly) id<RotoEventSource> deviceReader;

@end

@protocol DeviceProvider<NSObject>
@property id<Device> device;
@end

@interface RotoEventStream : NSObject<RotoEventSource, RotoEventHandler> {

}

- (void)addHandler:(id<RotoEventHandler>)handler;
- (void)removeHandler:(id<RotoEventHandler>)handler;
@end




#endif /* Event_h */
