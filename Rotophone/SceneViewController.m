//
//  SceneViewController.m
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SceneViewController.h"

static void* ShapeChangedKVOContext = &ShapeChangedKVOContext;

@implementation ConcreteMicrophone

@synthesize anchor, origin, rotation, shapeChanged;

CGFloat _microphoneRotation;

- (id)init {
    self = [super init];
    if (self != nil) {
        self.origin = NSMakePoint(20.0, 10.0);
        self.anchor = NSMakePoint(7.5, 7.5);
        self.rotation = 180;
        _microphoneRotation = 45;
    }
    return self;
}

- (void)acceptShapeVisitor:(id<ShapeVisitor>)visitor {
    [visitor visitMicrophoneShape:self];
}

- (NSSize)size {
    return NSMakeSize(15.0, 15.0);
}

- (CGFloat)microphoneRotation {
    return _microphoneRotation;
}

@end


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



@end


@interface SceneView ()
@property (retain) NSMutableArray *shapes;
@end

@implementation SceneView

CGFloat scale;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.shapes = [[NSMutableArray alloc] init];
    //[self addShape:[[ConcreteMicrophone alloc] init]];
    [self addShape:[[ConcreteRectangle alloc] init]];
    scale = 6.0;
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
    [path moveToPoint:NSMakePoint(0, 0)];
    [path lineToPoint:NSMakePoint(7.5, 15.0)];
    [path lineToPoint:NSMakePoint(15, 0)];
    [path closePath];
    [[NSColor purpleColor] set];
    [path fill];
    
    NSBezierPath *mic = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 1, 10)];
    
    NSAffineTransform* transform = [NSAffineTransform transform];
    [transform translateXBy:7 yBy:7.5];
    [transform rotateByRadians:shape.microphoneRotation];
    mic = [transform transformBezierPath:mic];
    [[NSColor greenColor] set];
    [mic fill];

    
    NSBezierPath *bounds = [NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, shape.size.width, shape.size.height)];
    [[NSColor whiteColor] set];
    [bounds stroke];
}

- (void)visitRectangleShape:(id<RectangleShape>)shape {
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, shape.size.width, shape.size.height)];
    [[NSColor redColor] set];
    [path fill];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    
    [[NSColor yellowColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform scaleBy:scale];
    [transform concat];
    for (id<Shape> shape in _shapes) {
        [context saveGraphicsState];
        NSAffineTransform *shapeTransform = [NSAffineTransform transform];
        [shapeTransform translateXBy:shape.origin.x yBy:shape.origin.y];
        [shapeTransform translateXBy:shape.anchor.x yBy:shape.anchor.y];
        [shapeTransform rotateByDegrees:shape.rotation];
        [shapeTransform translateXBy:-shape.anchor.x yBy:-shape.anchor.y];
        
        [shapeTransform concat];
        [shape acceptShapeVisitor:self];
        [context restoreGraphicsState];
        
    }
}
@end


@interface SceneViewController ()

@end

@implementation SceneViewController

- (void)loadView {
    [super loadView];
    // Do view setup here.
}

@end
