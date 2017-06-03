//
//  MicrophoneController.m
//  Rotophone
//
//  Created by z on 6/1/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MicrophoneController.h"

#import "Entities.h"

static void *SelectedPortKVOContext = &SelectedPortKVOContext;

@interface MicrophoneController () {
   MicrophoneEntity *_entity;
    BOOL _needsLoadData;
}

@property (retain) MicrophoneKeepAlive* keepAlive;

@end

@implementation MicrophoneController

@synthesize serialPortHandler = _serialPortHandler;

- (id)initWithEntity:(MicrophoneEntity *)entity {
    if (self = [super init]) {
        self.keepAlive = [[MicrophoneKeepAlive alloc] init];
        _keepAlive.delegate = self;
        _currentMode = kModeUnknown;
        _lastError = kErrCodeNone;
        _isConnected = false;
        _entity = entity;
        _needsLoadData = false;
    }
    
    return self;
}


- (SerialPortHandler *)serialPortHandler {
    return _serialPortHandler;
}

- (void)setSerialPortHandler:(SerialPortHandler *)serialPortHandler {
    if (serialPortHandler == _serialPortHandler) {
        return;
    }
    
    if (_serialPortHandler != nil) {
        [_serialPortHandler removeObserver:self forKeyPath:@"selectedPort"];
    }
    
    _serialPortHandler = serialPortHandler;
    if (_serialPortHandler != nil ) {
        [_serialPortHandler addObserver:self forKeyPath:@"selectedPort" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SelectedPortKVOContext];
    }
    
    [self handlePortChanged];
}



- (id<CommandWriter>)commandWriter {
    return _serialPortHandler.commandWriter;
}

- (void)handleEvent:(id<RotoEvent>)event {
    [event accept:self];
}

- (void)visitErrorEvent:(id<ErrorEvent>)event {
    NSLog(@"Got error code %d", event.errorCode);
    if (!_isConnected) {
        return; // Ignore if we don't have a confirmed channel
    }
    
    _lastError = event.errorCode;
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

- (void)handlePortChanged {
    
    [_keepAlive stop];
    _keepAlive.commandWriter = nil;
    [_serialPortHandler.eventStream removeHandler:self];
    [_serialPortHandler.eventStream removeHandler:_keepAlive];
    
    if (_serialPortHandler != nil && _serialPortHandler.selectedPort != nil) {
        _keepAlive.commandWriter = _serialPortHandler.commandWriter;
        [_keepAlive start];
        [_serialPortHandler.eventStream addHandler:self];
        [_serialPortHandler.eventStream addHandler:_keepAlive];
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

- (void)communicationDidBeginWithMode:(ModeType)mode {
    [self willChangeValueForKey:@"isConnected"];
    _isConnected = true;
    _needsLoadData = true;
    [self didChangeValueForKey:@"isConnected"];
    NSLog(@"communication started with mode %d", mode);
    _currentMode = mode;
    
    [self loadDataIfNecessary];
}

- (void)loadDataIfNecessary {
    if (_isConnected && _needsLoadData /*&& (_currentMode == kModeIdle || _currentMode == kModeRun)*/) {
        // Save data
        _needsLoadData = false;
        if (_entity.embeddedData != nil) {
            [self.commandWriter loadData:_entity.embeddedData];
            [self.commandWriter saveData];
        }
    }
}

- (void)communicationDidEnd {
    [self willChangeValueForKey:@"isConnected"];
    _isConnected = false;
    [self didChangeValueForKey:@"isConnected"];
    NSLog(@"communication ended");
    [self handlePortChanged];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == SelectedPortKVOContext) {
        // Do something with the balance…
        [self handlePortChanged];
    } else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
@end
