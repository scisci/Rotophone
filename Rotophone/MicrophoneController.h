//
//  MicrophoneController.h
//  Rotophone
//
//  Created by z on 6/1/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SerialPortHandler.h"
#import "MicrophoneKeepAlive.h"

@class MicrophoneEntity;

@protocol MicrophoneStatus<NSObject>
@property (readonly) BOOL isConnected;
@property (readonly) ModeType currentMode;
@end


@interface MicrophoneController : NSObject<RotoEventHandler, RotoEventVisitor, MicrophoneKeepAliveDelegate, MicrophoneStatus>

@property (retain) SerialPortHandler* serialPortHandler;
@property (readonly) id<CommandWriter> commandWriter;
@property (readonly) BOOL isConnected;
@property (readonly) ModeType currentMode;
@property (readonly) id<MicrophoneStatus> status;
@property (readonly) ErrCode lastError;

- (id)initWithEntity:(MicrophoneEntity *)entity;
@end
