//
//  SceneViewController.m
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SceneViewController.h"

static void* ShapeChangedKVOContext = &ShapeChangedKVOContext;

/*
@implementation ConcreteRectangle

@synthesize anchor, origin, rotation, shapeChanged;


- (id)init {
    self = [super init];
    if (self != nil) {
        self.origin = NSMakePoint(20.0, 10.0);
        self.anchor = NSMakePoint(7.5, 7.5);
        self.rotation = 3;
    }
    return self;
}

- (void)acceptShapeVisitor:(id<ShapeVisitor>)visitor {
    [visitor visitRectangleShape:self];
}

- (NSSize)size {
    return NSMakeSize(20.0, 1.0);
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"shapeChanged"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:[ShapeHelper shapeChangedKeyPaths]];
    }
    return keyPaths;
}

- (NSViewController *)createControlPanel {
    return nil;
}



@end

*/


@interface SceneView ()
@property (retain) NSMutableArray *shapes;
@property (retain) NSMutableArray *debugGraphics;
@end

@implementation SceneView


BOOL spaceDown;
@synthesize selection = _selection;

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.shapes = [[NSMutableArray alloc] init];
    self.debugGraphics = [[NSMutableArray alloc] init];
    spaceDown = false;
}

- (void)mouseDown:(NSEvent *)theEvent {
    
    NSPoint eventLocation = [theEvent locationInWindow];
    NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
    if (!spaceDown) {
        self.selection = [self hittest:localPoint];
    }
}

- (void)keyDown:(NSEvent *)theEvent {
    if ([theEvent keyCode] == 49) {
        spaceDown = true;
    }
}

- (void)keyUp:(NSEvent *)theEvent {
    if ([theEvent keyCode] == 49) {
        spaceDown = false;
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (_entity == nil) {
        return;
    }
    
    if (spaceDown) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform scaleBy:[_entity.scale floatValue]];
        [transform invert];
        NSPoint newDelta = [transform transformPoint:NSMakePoint(theEvent.deltaX, theEvent.deltaY)];
        
        _entity.tX = [NSNumber numberWithFloat:[_entity.tX floatValue] + newDelta.x];
        _entity.tY = [NSNumber numberWithFloat:[_entity.tY floatValue] - newDelta.y];
        [self setNeedsDisplay:YES];
    } else if (_selection != nil) {
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform scaleBy:[_entity.scale floatValue]];
        [transform invert];
        NSPoint newDelta = [transform transformPoint:NSMakePoint(theEvent.deltaX, theEvent.deltaY)];
        [_selection setOrigin: NSMakePoint(_selection.origin.x + newDelta.x, _selection.origin.y - newDelta.y)];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    [self setNeedsDisplay:YES];
}



- (NSObject<Shape>*)hittest:(NSPoint)point {
    if (_entity == nil) {
        return nil;
    }
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform scaleBy:[_entity.scale floatValue]];
    [transform translateXBy:[_entity.tX floatValue]    yBy:[_entity.tY floatValue]];
    for (id<Shape> shape in _shapes) {
        NSAffineTransform *shapeTransform = [[NSAffineTransform alloc] initWithTransform:transform];
        [ShapeHelper applyShapeTransform:shape ToTransform:shapeTransform];
        [shapeTransform invert];
        
        NSPoint hitPoint = [shapeTransform transformPoint:point];
        NSSize hitSize = [shape size];
        if (hitPoint.x >= 0 && hitPoint.y >= 0 && hitPoint.x < hitSize.width && hitPoint.y < hitSize.height) {
            return shape;
        }
    }
    
    return nil;
}

- (void)addShape:(NSObject<Shape>*)shape {
    [_shapes addObject:shape];
    
    // Listen to the shape
    [shape addObserver:self forKeyPath:@"shapeChanged" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:ShapeChangedKVOContext];

    [self setNeedsDisplay:YES];
}

- (void)removeShape:(NSObject<Shape>*)shape {
    [_shapes removeObject:shape];
    
    [shape removeObserver:self forKeyPath:@"shapeChanged"];
    
    [self setNeedsDisplay:YES];
}

- (void)addDebugGraphics:(NSObject<DebugGraphics> *)debugGraphics {
    [_debugGraphics addObject:debugGraphics];
}

- (void)removeDebugGraphics:(NSObject<DebugGraphics> *)debugGraphics {
    [_debugGraphics removeObject:debugGraphics];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == ShapeChangedKVOContext) {
        // Notify
        [self setNeedsDisplay:YES];
    } else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}


- (void)visitMicrophoneShape:(id<MicrophoneShape>)shape {
    NSBezierPath *path = [NSBezierPath bezierPath];
    //[path moveToPoint:NSMakePoint(0, 0)];
    //[path lineToPoint:NSMakePoint(7.5, 15.0)];
    //[path lineToPoint:NSMakePoint(15, 0)];
    
    [path moveToPoint:NSMakePoint(0, 0)];
    [path lineToPoint:NSMakePoint(15.0, 7.5)];
    [path lineToPoint:NSMakePoint(0, 15.0)];
    [path closePath];
    [[NSColor purpleColor] set];
    [path fill];
    
    NSBezierPath *mic = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, shape.pickupDist, 1)];
    
    NSAffineTransform* transform = [[NSAffineTransform alloc] init];
    [transform translateXBy:7.5 yBy:7.5];
    
    //NSGraphicsContext *context = [NSGraphicsContext currentContext];
    NSAffineTransform* posTransform = [[NSAffineTransform alloc] initWithTransform:transform];
    // Subtract 90 degrees to add additional rotation to the center point
    [posTransform rotateByRadians:[ShapeHelper clockwiseToCounterClockwise:shape.microphoneRotation]/* - M_PI * 0.5*/];
    NSBezierPath *micPosition = [posTransform transformBezierPath:mic];
    [[NSColor greenColor] set];
    [micPosition fill];
    //[context restoreGraphicsState];
    NSAffineTransform* targetTransform = [[NSAffineTransform alloc] initWithTransform:transform];
    // Subtract 90 degrees to add additional rotation to the zero point
    [targetTransform rotateByRadians:[ShapeHelper clockwiseToCounterClockwise:shape.microphoneTarget]/* - M_PI * 0.5*/];
    NSBezierPath *micTarget = [targetTransform transformBezierPath:mic];
    [[NSColor purpleColor] set];
    [micTarget fill];

    
    
}

- (void)visitRectangleShape:(id<RectangleShape>)shape {
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(0,0, shape.size.width, shape.size.height)];
    
    [[NSColor redColor] set];
    [path fill];
}



- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (_entity == nil) {
        return;
    }
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    
    [[NSColor yellowColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
    
    NSAffineTransform *transform = [NSAffineTransform transform];
   
    [transform scaleBy:[_entity.scale floatValue]];
    [transform translateXBy:[_entity.tX floatValue]    yBy:[_entity.tY floatValue]];
    [transform concat];
    for (id<Shape> shape in _shapes) {
        [context saveGraphicsState];
        NSAffineTransform *shapeTransform = [NSAffineTransform transform];
        
        [ShapeHelper applyShapeTransform:shape ToTransform:shapeTransform];
        [shapeTransform concat];
        [shape acceptShapeVisitor:self];
        

        if (shape == _selection) {
            NSBezierPath *bounds = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, shape.size.width, shape.size.height)];
            [[NSColor whiteColor] set];
            [bounds stroke];
        }
        [context restoreGraphicsState];
        
    }
    
    for (id<DebugGraphics> debugGraphics in _debugGraphics) {
        [debugGraphics drawDebugGraphics];
    }
}
@end


void *SceneViewSelectionKVOContext = &SceneViewSelectionKVOContext;

@interface SceneViewController ()

@end

@implementation SceneViewController

- (void)loadView {
    [super loadView];
    // Do view setup here.
    


}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
}

@end
