//
//  MicrophoneController.h
//  Rotophone
//
//  Created by z on 6/1/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MicrophoneKeepAlive.h"
#import "Event.h"



@class MicrophoneEntity;


@protocol MicrophoneTransport
- (BOOL)isStopped;
- (void)stop;
- (void)start;
- (void)calibrate;
@end


@protocol MicrophoneProxy
- (void)setZero;
- (void)setRotoTarget:(float)target;
- (void)setOrigin:(NSPoint)origin;
- (void)setBaseAnchor:(NSPoint)anchor;
- (void)setBaseRotation:(float)rotation;
- (id<MicrophoneTransport>)transport;
- (MicrophoneEntity *)entity;
@end

@protocol MicrophoneStatus<NSObject>
@property (readonly) BOOL isConnected;
@property (readonly) ModeType currentMode;
@end


@interface MicrophoneController : NSObject<RotoEventHandler, RotoEventVisitor, MicrophoneKeepAliveDelegate, MicrophoneStatus, MicrophoneProxy>

@property (readonly) id<Device> device;
@property (readonly) BOOL isConnected;
@property (readonly) ModeType currentMode;
@property (readonly) id<MicrophoneStatus> status;
@property (readonly) ErrCode lastError;

- (id)initWithEntity:(MicrophoneEntity *)entity andDeviceProvider:(NSObject<DeviceProvider> *)deviceProvider;
@end
