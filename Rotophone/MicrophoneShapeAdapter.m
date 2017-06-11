//
//  MicrophoneShapeAdapter.m
//  Rotophone
//
//  Created by z on 5/30/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MicrophoneShapeAdapter.h"
#import "MicrophoneControlPanelViewController.h"
#import "Entities.h"

static void* AnchorKVOContext = &AnchorKVOContext;
static void* RotationKVOContext = &RotationKVOContext;
static void* OriginKVOContext = &OriginKVOContext;
static void* RotoPositionKVOContext = &RotoPositionKVOContext;
static void* RotoTargetKVOContext = &RotoTargetKVOContext;

@interface MicrophoneShapeAdapter () {
}

@end

@implementation MicrophoneShapeAdapter

@synthesize microphoneRotation = _microphoneRotation;
@synthesize microphoneTarget =_microphoneTarget;
@synthesize rotation = _rotation;
@synthesize origin = _origin;
@synthesize anchor = _anchor;
@synthesize shapeChanged = _shapeChanged;

- (id)initWithProxy:(id<MicrophoneProxy>)proxy {
    self = [super init];
    if (self != nil) {
        self.proxy = proxy;
        MicrophoneEntity* model = proxy.entity;
        
        // Listen to changes to the model and notify anyone else
        [model addObserver:self forKeyPath:@"anchorX" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:AnchorKVOContext];
        [model addObserver:self forKeyPath:@"anchorY" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:AnchorKVOContext];
        [model addObserver:self forKeyPath:@"rotation" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:RotationKVOContext];
        [model addObserver:self forKeyPath:@"originX" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:OriginKVOContext];
        [model addObserver:self forKeyPath:@"originY" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:OriginKVOContext];
        [model addObserver:self forKeyPath:@"rotoPosition" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:RotoPositionKVOContext];
        [model addObserver:self forKeyPath:@"rotoTarget" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:RotoTargetKVOContext];

         _microphoneRotation = [model.rotoPosition floatValue];
        _microphoneTarget = [model.rotoTarget floatValue];
        _rotation = [model.rotation floatValue];
        _origin = CGPointMake([model.originX floatValue], [model.originY floatValue]);
        _anchor = CGPointMake([model.anchorX floatValue], [model.anchorY floatValue]);
    }
    return self;
}

- (void)dealloc {
    MicrophoneEntity* model = _proxy.entity;
    [model removeObserver:self forKeyPath:@"anchorX"];
    [model removeObserver:self forKeyPath:@"anchorY"];
    [model removeObserver:self forKeyPath:@"rotation"];
    [model removeObserver:self forKeyPath:@"originX"];
    [model removeObserver:self forKeyPath:@"originY"];
    [model removeObserver:self forKeyPath:@"rotoPosition"];
    [model removeObserver:self forKeyPath:@"rotoTarget"];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"anchor"] ||
        [theKey isEqualToString:@"rotation"] ||
        [theKey isEqualToString:@"origin"] ||
        [theKey isEqualToString:@"microphoneRotation"] ||
        [theKey isEqualToString:@"microphoneTarget"]) {
        automatic = NO;
    }
    else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}


+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"shapeChanged"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:[ShapeHelper shapeChangedKeyPaths]];
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"microphoneRotation", @"microphoneTarget"]];
    }
    return keyPaths;
}


- (NSViewController *)createControlPanel {
    MicrophoneControlPanelViewController* vc = [[MicrophoneControlPanelViewController alloc] initWithNibName:@"MicrophoneControlPanel" bundle:nil];
    vc.microphone = _proxy;
    return vc;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    MicrophoneEntity* model = _proxy.entity;
    if (context == RotoPositionKVOContext) {
        
        // Notify
        [self willChangeValueForKey:@"microphoneRotation"];
        _microphoneRotation = [model.rotoPosition floatValue];
        [self didChangeValueForKey:@"microphoneRotation"];
    } else if (context == RotationKVOContext) {
        [self willChangeValueForKey:@"rotation"];
        _rotation = [model.rotation floatValue];
         [self didChangeValueForKey:@"rotation"];
    } else if (context == RotoTargetKVOContext) {
        [self willChangeValueForKey:@"microphoneTarget"];
        _microphoneTarget = [model.rotoTarget floatValue];
        [self didChangeValueForKey:@"microphoneTarget"];
    } else if (context == OriginKVOContext) {
        [self willChangeValueForKey:@"origin"];
        _origin = CGPointMake([model.originX floatValue], [model.originY floatValue]);
        [self didChangeValueForKey:@"origin"];
    } else if (context == AnchorKVOContext) {
        [self willChangeValueForKey:@"anchor"];
        _anchor = CGPointMake([model.anchorX floatValue], [model.anchorY floatValue]);
        [self didChangeValueForKey:@"anchor"];
    } else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}


- (void)acceptShapeVisitor:(id<ShapeVisitor>)visitor {
    [visitor visitMicrophoneShape:self];
}

- (NSSize)size {
    return NSMakeSize(15.0, 15.0);
}

- (void)setMicrophoneRotation:(CGFloat)microphoneRotation {
    // TODO:
}

- (void)setMicrophoneTarget:(CGFloat)microphoneTarget {
    
}


- (void)setAnchor:(CGPoint)anchor {
    [_proxy setBaseAnchor:anchor];
}

- (void)setOrigin:(CGPoint)origin {
    [_proxy setOrigin:origin];
    
}

- (void)setRotation:(CGFloat)rotation {
    [_proxy setBaseRotation:rotation];
}

- (CGPoint)anchor {
    return CGPointMake(self.size.width/2, self.size.height/2);
    return _anchor;
}

- (CGPoint)origin {
    return _origin;}

- (CGFloat)rotation {
    return _rotation;
}

- (CGFloat)microphoneRotation {
    return _microphoneRotation;
}

@end
