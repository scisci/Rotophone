//
//  MicrophoneKeepAlive.h
//  Rotophone
//
//  Created by z on 6/2/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protocol.h"
#import "SerialPortHandler.h"
#import "Event.h"

@protocol MicrophoneKeepAliveDelegate
-(void)communicationDidBeginWithMode:(ModeType)mode;
-(void)communicationDidEnd;
@end



@interface MicrophoneKeepAlive : NSObject<RotoEventHandler, RotoEventVisitor> {
    BOOL _handshakeConfirmed;
    int _handshakeID;
    int _nextHandShakeID;
    NSDate *_lastHeartBeat;
    NSTimer *_handshakeTimer;
    NSTimer *_handhshakeRefreshTimer;
    NSTimer *_keepAliveTimeout;
}

- (void)start;
- (void)stop;
- (BOOL)isAlive;

@property (unsafe_unretained) id<MicrophoneKeepAliveDelegate> delegate;
@property (retain) id<RotoCommandWriter> commandWriter;
@end

