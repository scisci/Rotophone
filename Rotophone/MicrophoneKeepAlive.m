//
//  MicrophoneKeepAlive.m
//  Rotophone
//
//  Created by z on 6/2/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MicrophoneKeepAlive.h"


@implementation MicrophoneKeepAlive
- (id)init {
    if (self = [super init]) {
        _handshakeConfirmed = NO;
        _handshakeID = -1;
        _lastHeartBeat = nil;
    }
    
    return self;
}

- (void)handleHandshakeTimer:(id)sender {
    if (_handshakeConfirmed) {
        return;
    }
    
    _handshakeID = 15;
    if (_commandWriter != nil) {
        [_commandWriter sendHandshake:_handshakeID];
    }
}

- (void)handleKeepAliveTimer:(id)sender {
    if (!_handshakeConfirmed) {
        return;
    }
    
    if (_lastHeartBeat == nil || [_lastHeartBeat timeIntervalSinceNow] < -15.0) {
        [self stop];
    }
}

- (void)handleEvent:(id<RotoEvent>)event {
    [event accept:self];
}

- (void)visitHandshakeEvent:(id<HandshakeEvent>)event {
    if (_handshakeConfirmed) {
        return;
    }
    
    if (event.handshakeID == _handshakeID) {
        if (_handshakeTimer != nil) {
            [_handshakeTimer invalidate];
            _handshakeTimer = nil;
        }
        
        _handshakeConfirmed = true;
        _lastHeartBeat = [[NSDate alloc] init];
        [_delegate communicationDidBeginWithMode:event.mode];
        // Clear the watchdog timer
        if (_keepAliveTimeout != nil) {
            [_keepAliveTimeout invalidate];
            _keepAliveTimeout = nil;
        }
        
        _keepAliveTimeout = [NSTimer scheduledTimerWithTimeInterval: 15.0
                                                             target: self
                                                           selector: @selector(handleKeepAliveTimer:)
                                                           userInfo: nil
                                                            repeats: YES];
        
    }
}

- (void)visitHeartbeatEvent:(id<GenericEvent>)event {
    if (!_handshakeConfirmed) {
        return;
    }
    
    _lastHeartBeat = [[NSDate alloc] init];
    
    
}

- (BOOL)isAlive {
    return _handshakeConfirmed;
}

- (void)start {
    [self stop];
    
    _handshakeTimer = [NSTimer scheduledTimerWithTimeInterval: 2.0
                                                       target: self
                                                     selector: @selector(handleHandshakeTimer:)
                                                     userInfo: nil
                                                      repeats: YES];
}

- (void)stop {
    BOOL didEnd = _handshakeConfirmed == YES;
    
    _handshakeConfirmed = false;
    _handshakeID = -1;
    
    if (_handshakeTimer != nil) {
        [_handshakeTimer invalidate];
        _handshakeTimer = nil;
    }
    
    if (_keepAliveTimeout != nil) {
        [_keepAliveTimeout invalidate];
        _keepAliveTimeout = nil;
    }
    
    
    if (didEnd) {
        [_delegate communicationDidEnd];
    }
}

@end
