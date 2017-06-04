//
//  MicrophoneShapeAdapter.m
//  Rotophone
//
//  Created by z on 5/30/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MicrophoneShapeAdapter.h"

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

- (id)initWithModel:(MicrophoneEntity *)model {
    self = [super init];
    if (self != nil) {
        self.model = model;
        
        // Listen to changes to the model and notify anyone else
        [model addObserver:self forKeyPath:@"anchorX" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:AnchorKVOContext];
        [model addObserver:self forKeyPath:@"anchorY" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:AnchorKVOContext];
        [model addObserver:self forKeyPath:@"rotation" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:RotationKVOContext];
        [model addObserver:self forKeyPath:@"originX" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:OriginKVOContext];
        [model addObserver:self forKeyPath:@"originY" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:OriginKVOContext];
        [model addObserver:self forKeyPath:@"rotoPosition" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:RotoPositionKVOContext];
        [model addObserver:self forKeyPath:@"rotoTarget" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:RotoPositionKVOContext];

         _microphoneRotation = [_model.rotoPosition floatValue];
        _microphoneTarget = [_model.rotoTarget floatValue];
        _rotation = [_model.rotation floatValue];
        _origin = CGPointMake([_model.originX floatValue], [_model.originY floatValue]);
        _anchor = CGPointMake([_model.anchorX floatValue], [_model.anchorY floatValue]);
    }
    return self;
}

- (void)dealloc {
    [_model removeObserver:self forKeyPath:@"anchorX"];
    [_model removeObserver:self forKeyPath:@"anchorY"];
    [_model removeObserver:self forKeyPath:@"rotation"];
    [_model removeObserver:self forKeyPath:@"originX"];
    [_model removeObserver:self forKeyPath:@"originY"];
    [_model removeObserver:self forKeyPath:@"rotoPosition"];
    [_model removeObserver:self forKeyPath:@"rotoTarget"];
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
        NSArray *affectingKeys = @[@"anchor", @"origin", @"rotation", @"microphoneRotation", @"microphoneTarget"];
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    return keyPaths;
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == RotoPositionKVOContext) {
        // Notify
        [self willChangeValueForKey:@"microphoneRotation"];
        _microphoneRotation = [_model.rotoPosition floatValue];
        [self didChangeValueForKey:@"microphoneRotation"];
    } else if (context == RotationKVOContext) {
        [self willChangeValueForKey:@"rotation"];
        _rotation = [_model.rotation floatValue];
         [self didChangeValueForKey:@"rotation"];
    } else if (context == RotoTargetKVOContext) {
        [self willChangeValueForKey:@"microphoneTarget"];
        _microphoneTarget = [_model.rotoTarget floatValue];
        [self didChangeValueForKey:@"microphoneTarget"];
    } else if (context == OriginKVOContext) {
        [self willChangeValueForKey:@"origin"];
        _origin = CGPointMake([_model.originX floatValue], [_model.originY floatValue]);
        [self didChangeValueForKey:@"origin"];
    } else if (context == AnchorKVOContext) {
        [self willChangeValueForKey:@"anchor"];
        _anchor = CGPointMake([_model.anchorX floatValue], [_model.anchorY floatValue]);
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
    // TODO:
}

- (void)setOrigin:(CGPoint)origin {
    // TODO:
    _model.originX = [NSNumber numberWithFloat:origin.x];
    _model.originY = [NSNumber numberWithFloat:origin.y];
}

- (void)setRotation:(CGFloat)rotation {
    // TODO:
}

- (CGPoint)anchor {
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
