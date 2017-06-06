//
//  Event.m
//  Rotophone
//
//  Created by z on 5/30/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Event.h"

@interface HandlerChange : NSObject {
    @public
    id<RotoEventHandler> _handler;
    BOOL _add;
}


@end

@implementation HandlerChange

- (id)initWithHandler:(id<RotoEventHandler>)handler Add:(BOOL)add {
    if (self = [super init]) {
        _handler = handler;
        _add = add;
    }
    return self;
    
}

@end

@interface RotoEventStream () {
   NSMutableArray* handlers;
    NSMutableArray* changes;
    BOOL _dispatching;
}

@end

@implementation RotoEventStream

- (id)init {
    if (self = [super init]) {
        handlers = [[NSMutableArray alloc] init];
        changes = [[NSMutableArray alloc] init];
        _dispatching = NO;
    }
    return self;
}

- (void)handleEvent:(id<RotoEvent>)event {
    _dispatching = true;
    for (id<RotoEventHandler> existingHandler in handlers) {
        [existingHandler handleEvent:event];
    }
    _dispatching = false;
    
    if (![changes count]) {
        for (HandlerChange *change in changes) {
            if (change->_add) {
                [self addHandler:change->_handler];
            } else {
                [self removeHandler:change->_handler];
            }
        }
        
        [changes removeAllObjects];
    }
}

- (void)addHandler:(id<RotoEventHandler>)handler {
    if (_dispatching) {
        [changes addObject:[[HandlerChange alloc] initWithHandler:handler Add:YES]];
        return;
    }
    
    for (id<RotoEventHandler> existingHandler in handlers) {
        if (existingHandler == handler) {
            return;
        }
    }
    
    [handlers addObject:handler];
}
- (void)removeHandler:(id<RotoEventHandler>)handler {
    if (_dispatching) {
        [changes addObject:[[HandlerChange alloc] initWithHandler:handler Add:NO]];
        return;
    }
    
    [handlers removeObject:handler];
}

@end




@interface ConcreteUpdatePosEvent () {
    double _timestamp;
    unsigned char _rotoID;
    float _position;
}


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


@interface ConcreteDataEvent () {
    double _timestamp;
    unsigned char _rotoID;
    NSData* _data;
    TxEvent _type;
}


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


@interface ConcreteHandshakeEvent () {
    double _timestamp;
    unsigned char _rotoID;
    int _handshakeID;
    ModeType _mode;
}


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



@interface ConcreteUpdateModeEvent () {
    double _timestamp;
    unsigned char _rotoID;
    ModeType _mode;
}


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





@interface ConcreteErrorEvent () {
    double _timestamp;
    unsigned char _rotoID;
    ErrCode _errorCode;
}


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





@interface ConcreteGenericEvent () {
    double _timestamp;
    unsigned char _rotoID;
    TxEvent _eventType;
}
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


