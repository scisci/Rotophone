//
//  MockDevice.m
//  Rotophone
//
//  Created by z on 6/6/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MockDevice.h"

static void *DeviceKVOContext = &DeviceKVOContext;

@implementation DeviceProviderSelector
@synthesize deviceProvider = _deviceProvider;
@synthesize device;


- (NSObject<DeviceProvider> *)deviceProvider {
    return _deviceProvider;
}

- (void)reload {
    if (_deviceProvider != nil) {
        [_deviceProvider reload];
    }
}

- (void)setDeviceProvider:(NSObject<DeviceProvider> *)deviceProvider {
    if (_deviceProvider != nil) {
        [_deviceProvider removeObserver:self forKeyPath:@"device"];
    }
    
    _deviceProvider = deviceProvider;
    
    if (_deviceProvider != nil) {
        [_deviceProvider addObserver:self forKeyPath:@"device" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:DeviceKVOContext];
        self.device = _deviceProvider.device;
    } else {
        self.device = nil;
    }

}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == DeviceKVOContext) {
        self.device = _deviceProvider.device;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
- (void)dealloc {
    self.deviceProvider = nil;
}
@end

@interface MockDevice () {
    NSTimer* _keepAliveTimer;
    RotoEventStream* _eventStream;
    ModeType _mode;
    float _target;
    int _handshakeID;
    float _rotation;
    NSTimer* _rotationTimer;
    
    ModeType _nextMode;
    NSTimer* _nextModeTimer;
}

@end

@implementation MockDevice

-(id)init {
    if (self = [super init]) {
        _eventStream = [[RotoEventStream alloc] init];
        _mode = kModeStartup;
        _rotation = 0;
        _target = 0;
        _handshakeID = -1;
    
    }
    return self;
}


- (void)reload {
    NSLog(@"can't reload mock device.");
}

- (id<RotoCommandWriter>)deviceWriter {
    return self;
}

- (id<RotoEventSource>)deviceReader {
    return self;
}

- (void)setDevice:(id<Device>)device {
    
}

- (void)changeModeTo:(ModeType)mode In:(double)seconds {
    if (_nextModeTimer != nil) {
        [_nextModeTimer invalidate];
        _nextModeTimer = nil;
    }
    
    _nextMode = mode;
    
    [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(nextMode:) userInfo:nil repeats:NO];
}

- (void)nextMode:(id)sender {
    if (_nextModeTimer != nil) {
        [_nextModeTimer invalidate];
        _nextModeTimer = nil;
    }
    
    [self setMode:_nextMode];
    
    if (_nextMode == kModeIdle) {
        [self changeModeTo:kModeRun In:5.0];
    }
}

- (id<Device>)device {
    return self;
}

- (void)addHandler:(id<RotoEventHandler>)handler {
    [_eventStream addHandler:handler];
}
- (void)removeHandler:(id<RotoEventHandler>)handler {
    [_eventStream removeHandler:handler];
}


- (void)setPosition:(float)position {
    
    
    // Get the target on the unit circle
    _target = fmod(position, 2 * M_PI);//position - floorf(position / (2 * M_PI)) * 2 * M_PI;
    if (_target < 0) {
        _target += 2 * M_PI;
    }
    
    if (_rotation == _target) {
        [_eventStream handleEvent:[[ConcreteUpdatePosEvent alloc] initWithTimestamp:0.0 rotoID:0 andPosition:_rotation]];
        return;
    }
    [self startRotationIfNecessary];
    
}

- (void)startRotationIfNecessary {
    if (_rotationTimer == nil) {
    _rotationTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:0.1 target:self selector:@selector(updatePosition:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_rotationTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)updatePosition:(id)sender {
    
    // Find the smallest angle between _target
    float dif = _target - _rotation;
    if (dif > M_PI) {
        dif -= 2 * M_PI;
    } else if (dif < - M_PI) {
        dif += 2 * M_PI;
    }
    
    if (fabs(dif) < 0.000001) {
        [_rotationTimer invalidate];
        _rotationTimer = nil;
        return;
    }
    
    _rotation += dif * 0.1;
    if (_rotation > 2 * M_PI) {
        _rotation -= 2 * M_PI;
    } else if (_rotation < 0) {
        _rotation += 2 * M_PI;
    }
    
    [_eventStream handleEvent:[[ConcreteUpdatePosEvent alloc] initWithTimestamp:0.0 rotoID:0 andPosition:_rotation]];
    
    
    
}

- (void)setMode:(ModeType)mode {
    if (mode == _mode) {
        return;
    }
    
    _mode = mode;
    
    [_eventStream handleEvent:[[ConcreteUpdateModeEvent alloc] initWithTimestamp:0.0 rotoID:0 Mode:_mode]];
}

- (void)sendHandshake:(unsigned char)handshakeID {
    BOOL startTimer = false;
    if (handshakeID != _handshakeID) {
        startTimer = YES;
    }
    _handshakeID = handshakeID;
    
    
    [_eventStream handleEvent:[[ConcreteHandshakeEvent alloc] initWithTimestamp:0.0 rotoID:0 HandshakeID:handshakeID Mode:_mode]];
    
    if (startTimer) {
        if (_keepAliveTimer != nil) {
            [_keepAliveTimer invalidate];
            _keepAliveTimer = nil;
        }
        
        _keepAliveTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:10.0 target:self selector:@selector(handleKeepAliveTimer:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_keepAliveTimer forMode:NSRunLoopCommonModes];
        
        
        [self changeModeTo:kModeIdle In:5.0];
    }
}

- (void)handleKeepAliveTimer:(id)sender {
    [_eventStream handleEvent:[[ConcreteGenericEvent alloc] initWithTimestamp:0.0 rotoID:0 EventType:kHeartBeatEvent]];

}

- (void)setZero {
    NSLog(@"MockDevice::setZero");
}

- (void)loadData:(NSData *)data {
    // NOOP
}

- (void)saveData {
    // NOOP
}

@end
