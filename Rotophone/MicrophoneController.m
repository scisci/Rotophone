//
//  MicrophoneController.m
//  Rotophone
//
//  Created by z on 6/1/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MicrophoneController.h"

#import "Entities.h"

static void* DeviceKVOContext = &DeviceKVOContext;

@interface MicrophoneController () {
   MicrophoneEntity *_entity;
    NSObject<DeviceProvider> *_deviceProvider;
    BOOL _needsLoadData;
}

@property (retain) MicrophoneKeepAlive* keepAlive;

@end

@implementation MicrophoneController

- (id)initWithEntity:(MicrophoneEntity *)entity andDeviceProvider:(NSObject<DeviceProvider> *)deviceProvider {
    if (self = [super init]) {
        self.keepAlive = [[MicrophoneKeepAlive alloc] init];
        _keepAlive.delegate = self;
        _currentMode = kModeUnknown;
        _lastError = kErrCodeNone;
        _isConnected = false;
        _entity = entity;
        _needsLoadData = false;
        
        // Listen to changes in the device
        _deviceProvider = deviceProvider;
        [_deviceProvider addObserver:self forKeyPath:@"device" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:DeviceKVOContext];
        
        if (_deviceProvider.device != nil) {
            [self handleDeviceChangedFrom:nil ToDevice:_deviceProvider.device];
        }
    
    }
    
    return self;
}

- (id<MicrophoneTransport>)transport {
    return nil;
}

- (id<Device>)device {
    return _deviceProvider.device;
}

- (void)setZero {
    id<Device> d = self.device;
    if (d != nil) {
        
        [d.deviceWriter setZero];
    }
}

- (void)setOrigin:(NSPoint)origin {
    _entity.originX = [NSNumber numberWithFloat:origin.x];
    _entity.originY = [NSNumber numberWithFloat:origin.y];
}

- (void)setBaseAnchor:(NSPoint)anchor {
    _entity.anchorX = [NSNumber numberWithFloat:anchor.x];
    _entity.anchorY = [NSNumber numberWithFloat:anchor.y];
}

- (void)setBaseRotation:(float)rotation {
    _entity.rotation = [NSNumber numberWithFloat:rotation];
}

- (void)setRotoTarget:(float)target {
    if (target < 0) {
        target = 0;
    } else if (target > 2 * M_PI) {
        target = 2 * M_PI;
    }
    
    if (target == _entity.rotoTarget.floatValue) {
        return;
    }
    
    _entity.rotoTarget = [NSNumber numberWithFloat:target];
    if (self.device != nil) {
        [self.device.deviceWriter setPosition:target];
    }
}

- (void)handleEvent:(id<RotoEvent>)event {
    [event accept:self];
}

- (void)visitUpdatePosEvent:(id<UpdatePosEvent>)event {
    _entity.rotoPosition = [NSNumber numberWithFloat:event.position];
}

- (void)visitErrorEvent:(id<ErrorEvent>)event {
    NSLog(@"Got error code %d", event.errorCode);
    if (!_isConnected) {
        return; // Ignore if we don't have a confirmed channel
    }
    
    _lastError = event.errorCode;
}

- (void)loadDataIfNecessary {
    if (_isConnected && _needsLoadData /*&& (_currentMode == kModeIdle || _currentMode == kModeRun)*/) {
        // Save data
        _needsLoadData = false;
        if (_entity.embeddedData != nil && self.device != nil) {
            [self.device.deviceWriter loadData:_entity.embeddedData];
            [self.device.deviceWriter saveData];
        }
    }
}


- (void)visitUpdateModeEvent:(id<UpdateModeEvent>)event {
    NSLog(@"Changed modes to %d", event.mode);
    if (!_isConnected) {
        return; // Ignore if we don't have a confirmed channel
    }
    
    [self willChangeValueForKey:@"currentMode"];
    _currentMode = event.mode;
    [self didChangeValueForKey:@"currentMode"];
    
    [self loadDataIfNecessary];
}

- (void)visitSaveEvent:(id<DataEvent>)event {
    NSLog(@"Save data");
    if (!_isConnected) {
        return;
    }
    _entity.embeddedData = event.data;

}

- (void)handleDeviceChangedFrom:(id<Device>)prev ToDevice:(id<Device>)next {
    
    [_keepAlive stop];
    _keepAlive.commandWriter = nil;
    
    if (prev != nil) {
        [prev.deviceReader removeHandler:self];
        [prev.deviceReader removeHandler:_keepAlive];
    }
    
    if (next != nil) {
        _keepAlive.commandWriter = next.deviceWriter;
        [_keepAlive start];
        [next.deviceReader addHandler:self];
        [next.deviceReader addHandler:_keepAlive];
    }
}


+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"isConnected"] ||
        [theKey isEqualToString:@"currentMode"]) {
        automatic = NO;
    }
    else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"status"]) {
        NSArray *affectingKeys = @[@"isConnected", @"currentMode"];
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    return keyPaths;
}

- (id<MicrophoneStatus>)status {
    return self;
}

- (MicrophoneEntity *)entity {
    return _entity;
}

- (void)communicationDidBeginWithMode:(ModeType)mode {
    [self willChangeValueForKey:@"isConnected"];
    _isConnected = true;
    _needsLoadData = true;
    [self didChangeValueForKey:@"isConnected"];
    NSLog(@"communication started with mode %d", mode);
    _currentMode = mode;
    
    [self loadDataIfNecessary];
}


- (void)communicationDidEnd {
    [self willChangeValueForKey:@"isConnected"];
    _isConnected = false;
    [self didChangeValueForKey:@"isConnected"];
    NSLog(@"communication ended");

    // Attempt to reconnect?
    [self attemptReconnect];
}

- (void)attemptReconnect {
    if (self.device == nil) {
        return;
    }
    
    [_keepAlive stop];
    [_keepAlive start];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == DeviceKVOContext) {
        NSObject* prev = [change objectForKey:NSKeyValueChangeOldKey];
        NSObject* next = [change objectForKey:NSKeyValueChangeNewKey];
        id<Device> prevDevice = prev == nil || prev == [NSNull null] ? nil : (id<Device>)prev;
        id<Device> nextDevice = next == nil || next == [NSNull null] ? nil : (id<Device>)next;
        [self handleDeviceChangedFrom:prevDevice ToDevice:nextDevice];
    } else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
@end
