//
//  FieldShapeAdapter.m
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "FieldShapeAdapter.h"

static void* AnchorKVOContext = &AnchorKVOContext;
static void* RotationKVOContext = &RotationKVOContext;
static void* OriginKVOContext = &OriginKVOContext;
static void* WidthKVOContext = &WidthKVOContext;
static void* HeightKVOContext = &HeightKVOContext;

@implementation FieldShapeAdapter

@synthesize rectangleSize = _rectangleSize;
@synthesize rotation = _rotation;
@synthesize origin = _origin;
@synthesize anchor = _anchor;
@synthesize shapeChanged = _shapeChanged;


- (id)initWithEntity:(FieldEntity *)entity {
    self = [super init];
    if (self != nil) {
        self.entity = entity;
        FieldEntity* model = entity;
        
        // Listen to changes to the model and notify anyone else
        [model addObserver:self forKeyPath:@"anchorX" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:AnchorKVOContext];
        [model addObserver:self forKeyPath:@"anchorY" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:AnchorKVOContext];
        [model addObserver:self forKeyPath:@"rotation" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:RotationKVOContext];
        [model addObserver:self forKeyPath:@"originX" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:OriginKVOContext];
        [model addObserver:self forKeyPath:@"originY" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:OriginKVOContext];
        [model addObserver:self forKeyPath:@"width" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:WidthKVOContext];
        [model addObserver:self forKeyPath:@"height" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:HeightKVOContext];
        
        _rectangleSize = NSMakeSize([model.width floatValue], [model.height floatValue]);
        _rotation = [model.rotation floatValue];
        _origin = CGPointMake([model.originX floatValue], [model.originY floatValue]);
        _anchor = CGPointMake([model.anchorX floatValue], [model.anchorY floatValue]);
    }
    return self;
}

- (void)dealloc {
    FieldEntity* model = _entity;
    [model removeObserver:self forKeyPath:@"anchorX"];
    [model removeObserver:self forKeyPath:@"anchorY"];
    [model removeObserver:self forKeyPath:@"rotation"];
    [model removeObserver:self forKeyPath:@"originX"];
    [model removeObserver:self forKeyPath:@"originY"];
    [model removeObserver:self forKeyPath:@"width"];
    [model removeObserver:self forKeyPath:@"height"];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"anchor"] ||
        [theKey isEqualToString:@"rotation"] ||
        [theKey isEqualToString:@"origin"] ||
        [theKey isEqualToString:@"rectangleSize"]) {
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
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"rectangleSize"]];
    }
    return keyPaths;
}


- (NSViewController *)createControlPanel {
    return nil;
    /*
    MicrophoneControlPanelViewController* vc = [[MicrophoneControlPanelViewController alloc] initWithNibName:@"MicrophoneControlPanel" bundle:nil];
    vc.microphone = _proxy;
    return vc;
     */
}

- (void)acceptShapeVisitor:(id<ShapeVisitor>)visitor {
    [visitor visitRectangleShape:self];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    FieldEntity* model = _entity;
    if (context == WidthKVOContext || context == HeightKVOContext) {
        
        // Notify
        [self willChangeValueForKey:@"rectangleSize"];
        _rectangleSize = NSMakeSize([model.width floatValue], [model.height floatValue]);
        [self didChangeValueForKey:@"rectangleSize"];
    } else if (context == RotationKVOContext) {
        [self willChangeValueForKey:@"rotation"];
        _rotation = [model.rotation floatValue];
        [self didChangeValueForKey:@"rotation"];
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



- (NSSize)size {
    return _rectangleSize;
}



@end
