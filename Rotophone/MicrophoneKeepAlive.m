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
        srand((unsigned int)time(NULL));
        _nextHandShakeID = rand() & 0xFF;
        _lastHeartBeat = nil;
    }
    
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)handleHandshakeTimer:(id)sender {
    if (_handshakeConfirmed) {
        NSLog(@"Polling for device, but already confirmed!");
        return;
    }
    
    if ([_startTime timeIntervalSinceNow] < -20.0) {
        if (_delegate != nil) {
            NSLog(@"Requesting reload.");
            [_delegate reloadDevice];
        }
    }
    
    NSLog(@"Polling for device");
    _handshakeID = _nextHandShakeID;
    _nextHandShakeID = (_nextHandShakeID + 1) & 0xFF;
    if (_commandWriter != nil) {
        [_commandWriter sendHandshake:_handshakeID];
    } else {
        NSLog(@"No command writer to poll!");
    }
    
    
}

- (void)handleKeepAliveTimer:(id)sender {
    if (!_handshakeConfirmed) {
        return;
    }
    
    if (_lastHeartBeat == nil || [_lastHeartBeat timeIntervalSinceNow] < -15.0) {
        NSLog(@"Lost device.");
        [self stop];
    }
}

- (void)handleHandshakeRefreshTimer:(id)sender {
    if (_commandWriter != nil) {
        [_commandWriter sendHandshake:_handshakeID];
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

        // Here we check to see if we lost connection
        _keepAliveTimeout = [[NSTimer alloc] initWithFireDate:[NSDate date] interval: 15.0
                                                             target: self
                                                           selector: @selector(handleKeepAliveTimer:)
                                                           userInfo: nil
                                                            repeats: YES];
        [[NSRunLoop currentRunLoop] addTimer:_keepAliveTimeout forMode:NSRunLoopCommonModes];
        
        // Here we tell the device that we didn't lose connection
        _handhshakeRefreshTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval: 10.0
                                                                   target: self
                                                                 selector: @selector(handleHandshakeRefreshTimer:)
                                                                 userInfo: nil
                                                                  repeats: YES];
        [[NSRunLoop currentRunLoop] addTimer:_handhshakeRefreshTimer forMode:NSRunLoopCommonModes];
        
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
    
    _startTime = [NSDate date];
    _handshakeTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval: 2.0
                                                       target: self
                                                     selector: @selector(handleHandshakeTimer:)
                                                     userInfo: nil
                                                      repeats: YES];
    
    [[NSRunLoop currentRunLoop] addTimer:_handshakeTimer forMode:NSRunLoopCommonModes];
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
    
    if (_handhshakeRefreshTimer != nil) {
        [_handhshakeRefreshTimer invalidate];
        _handhshakeRefreshTimer = nil;
    }
    
    
    if (didEnd && _delegate != nil) {
        [_delegate communicationDidEnd];
    }
}

@end
