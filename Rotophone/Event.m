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
