//
//  SimulationController.m
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SimulationController.h"
#import "Shape.h"
#import "MicrophoneShapeAdapter.h"
#import "FieldShapeAdapter.h"
#import "GPCPolygon.h"
#include "gpc.h"


static void* SimBodyKVOContext = &SimBodyKVOContext;

static void* SimMicKVOContext = &SimMicKVOContext;

static void initPolyWithPoints(gpc_polygon* poly, NSPoint *points, int numPoints) {
    // allocate memory for the gpcPolygon.
    poly->contour = NULL;
    poly->hole = NULL;
    
    if (numPoints < 2) {
        poly->num_contours = 0;
        return;
    }
    
    // Initialize with a single contour and populate it with the points from the array
    poly->num_contours = 1;
    poly->contour = (gpc_vertex_list *) malloc( sizeof( gpc_vertex_list ) * poly->num_contours );
   // poly->hole = (int *)malloc( sizeof( int ) * poly->num_contours );
    //poly->hole[0] = 0;
    
    if ( poly->contour == NULL ) {
        gpc_free_polygon(poly);
        return;
    }
    
    // allocate enough memory to hold this many points
    poly->contour[0].num_vertices = numPoints;
    poly->contour[0].vertex = (gpc_vertex *) malloc( sizeof( gpc_vertex ) * numPoints );
    for( NSInteger idx = 0; idx < numPoints; ++idx )
    {
        //CGPoint pnt = [[points objectAtIndex:idx] pointValue];
        poly->contour[0].vertex[idx].x = points[idx].x;
        poly->contour[0].vertex[idx].y = points[idx].y;
    }
    
    // Find hole status from winding direction
    //poly->hole[0] = NO;//[self isHoleFromWinding];

}

@interface SimulationMicrophone : NSObject {
    @public
    gpc_polygon poly;
    BOOL dirty;
}

@property (unsafe_unretained) id<SimulationBodyDelegate> delegate;
@property (retain) MicrophoneShapeAdapter* microphoneShape;
@end;

@implementation SimulationMicrophone
- (id) initWithMicrophoneProxy:(NSObject<MicrophoneProxy> *)proxy {
    if (self = [super init]) {
        self.microphoneShape = [[MicrophoneShapeAdapter alloc] initWithProxy:proxy];
        
        [_microphoneShape addObserver:self forKeyPath:@"shapeChanged" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimMicKVOContext];

        
        int numPoints = 3;
        NSPoint points[] = {NSMakePoint(0,0), NSMakePoint(0, 10), NSMakePoint(10,10)};
        
        initPolyWithPoints(&poly, &points[0], numPoints);
        dirty = YES;
        //[self updatePoints];
    }
    return self;
}

- (void)updatePoints {
    // Take our shape and transform it
    NSAffineTransform* transform = [NSAffineTransform transform];
    [ShapeHelper applyShapeTransform:_microphoneShape ToTransform:transform];
    
    [transform translateXBy:7.5 yBy:7.5];
    [transform rotateByRadians:[ShapeHelper clockwiseToCounterClockwise:_microphoneShape.microphoneRotation]];
    
    // Mic distance is 240 inches (20 ft)
    // Mic angle is 5 degrees
    
    float micDist = 240.0;
    float micAngle = 20 * M_PI / 180.0;
    
    float xOffset1 = cosf(micAngle) * micDist;
    float yOffset1 = sinf(micAngle) * micDist;
    
    float xOffset2 = cosf(-micAngle) * micDist;
    float yOffset2 = sinf(-micAngle) * micDist;
    // Transform each point
    int numPoints = 3;
    NSPoint points[] = {NSMakePoint(0,0), NSMakePoint(xOffset1, yOffset1), NSMakePoint(xOffset2,yOffset2)};
    for (int i = 0; i < numPoints;i++) {
        NSPoint tp = [transform transformPoint:points[i]];
        poly.contour[0].vertex[i].x = tp.x;
        poly.contour[0].vertex[i].y = tp.y;
    }
    
    dirty = false;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SimMicKVOContext) {
        if (_delegate != nil) {
            // Update our points
            
            dirty = YES;
            [_delegate simulationMicChanged:self];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [_microphoneShape removeObserver:self forKeyPath:@"shapeChanged"];
    gpc_free_polygon(&poly);
}
@end




@interface SimulationBody : NSObject {
    @public
    gpc_polygon poly;
    gpc_tristrip intersectionArea;
    BOOL dirty;
}


@property (unsafe_unretained) id<SimulationBodyDelegate> delegate;
@property (retain) FieldEntity* field;
@property (retain) BodyEntity* body;
@property (retain) FieldShapeAdapter* fieldShape;

@end

@implementation SimulationBody
- (id) initWithBody:(BodyEntity *)body {
    if (self = [super init]) {
        self.body = body;
        self.field = [[body.fields allObjects] objectAtIndex:0];
        
        // TODO: listen to changes to the body
        self.fieldShape = [[FieldShapeAdapter alloc] initWithEntity:_field];
        
        [_fieldShape addObserver:self forKeyPath:@"shapeChanged" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimBodyKVOContext];
        /*
        [_field addObserver:self forKeyPath:@"width" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimBodyKVOContext];
        [_field addObserver:self forKeyPath:@"height" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimBodyKVOContext];
        [_field addObserver:self forKeyPath:@"originX" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimBodyKVOContext];
        [_field addObserver:self forKeyPath:@"originY" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimBodyKVOContext];
        [_field addObserver:self forKeyPath:@"rotation" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimBodyKVOContext];
        */
        
        int numPoints = 4;
        NSPoint points[] = {NSMakePoint(0,0), NSMakePoint(0, 10), NSMakePoint(10,10), NSMakePoint(10, 0)};
        
            initPolyWithPoints(&poly, &points[0], numPoints);
        intersectionArea.strip = NULL;
        intersectionArea.num_strips = 0;
        dirty = YES;
        //[self updatePoints];
    }
    return self;
}

- (void)updatePoints {
    // Take our shape and transform it
    NSAffineTransform* transform = [NSAffineTransform transform];
    [ShapeHelper applyShapeTransform:_fieldShape ToTransform:transform];
    
    float width = _field.width.floatValue;
    float height = _field.height.floatValue;
    //NSBezierPath *rect = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, _field.width.floatValue, _field.height.floatValue)];
    //[transform transformBezierPath:rect];
    
    // Transform each point
    int numPoints = 4;
    NSPoint points[] = {NSMakePoint(0,0), NSMakePoint(0, height), NSMakePoint(width,height), NSMakePoint(width, 0)};
    for (int i = 0; i < numPoints;i++) {
        NSPoint tp = [transform transformPoint:points[i]];
        poly.contour[0].vertex[i].x = tp.x;
        poly.contour[0].vertex[i].y = tp.y;
    }
    
    dirty = false;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SimBodyKVOContext) {
        if (_delegate != nil) {
            // Update our points
            
            dirty = YES;
            [_delegate simulationBodyChanged:self];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [_field removeObserver:self forKeyPath:@"shapeChanged"];
    /*
    [_field removeObserver:self forKeyPath:@"width"];
    [_field removeObserver:self forKeyPath:@"height"];
    [_field removeObserver:self forKeyPath:@"originX"];
    [_field removeObserver:self forKeyPath:@"originY"];
    [_field removeObserver:self forKeyPath:@"rotation"];
     */
    gpc_free_polygon(&poly);
    gpc_free_tristrip(&intersectionArea);
}
@end


@interface SimulationController () {
    NSArray* _bodies;
    SimulationMicrophone* _microphone;
    NSTimer* _simulationTimer;
    gpc_polygon _intersection;
    
    BOOL _sceneDirty;
}

@end

@implementation SimulationController
@synthesize scene = _scene;
- (id)init {
    if (self = [super init]) {
        _bodies = [[NSArray alloc] init];
        
        _intersection.contour = NULL;
        _intersection.hole = NULL;
        _intersection.num_contours = 0;

        _sceneDirty = true;
        

        
    }
    return self;
}

- (NSObject<Scene> *)scene {
    return _scene;
}
- (void)setScene:(NSObject<Scene> *)scene {
    if (_scene != nil) {
        [_scene removeDebugGraphics:self];
    }
    _scene = scene;
    if (_scene != nil) {
        [_scene addDebugGraphics:self];
    }
}

- (void)dealloc {
    self.scene = nil;
     gpc_free_polygon(&_intersection);
}

- (void)start {
    if (_simulationTimer != nil) {
        return;
    }
    
    _simulationTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval: 0.1
                                                  target: self
                                                selector: @selector(updateSimulation:)
                                                userInfo: nil
                                                 repeats: YES];
    [[NSRunLoop currentRunLoop] addTimer:_simulationTimer forMode:NSRunLoopCommonModes];
}

- (void)drawDebugGraphics {
    // Draw all of the intersections
    if (_microphone == nil) {
        return;
    }
    
    //NSGraphicsContext *context = [NSGraphicsContext currentContext];
    
    for (SimulationBody *body in _bodies) {
        for (int i = 0 ; i < body->intersectionArea.num_strips ; i++)
        {
            NSBezierPath *path = [NSBezierPath bezierPath];
            for (int j = 0 ; j < body->intersectionArea.strip[i].num_vertices-2 ; j++) {
                [path moveToPoint:NSMakePoint(body->intersectionArea.strip[i].vertex[j].x,body->intersectionArea.strip[i].vertex[j].y)];
                [path lineToPoint:NSMakePoint(body->intersectionArea.strip[i].vertex[j+1].x,body->intersectionArea.strip[i].vertex[j+1].y)];
                [path lineToPoint:NSMakePoint(body->intersectionArea.strip[i].vertex[j+2].x,body->intersectionArea.strip[i].vertex[j+2].y)];
            
            }
            [[NSColor brownColor] set];
            [path fill];
        }
    }
}

- (void)stop {
    if (_simulationTimer == nil) {
        return;
    }
    
    [_simulationTimer invalidate];
    _simulationTimer = nil;
}



- (void)addMicrophone:(NSObject<MicrophoneProxy> *)proxy {
    if (_microphone != nil) {
        NSLog(@"oops don't set multiple microphones!");
    }
    _microphone = [[SimulationMicrophone alloc] initWithMicrophoneProxy:proxy];
    _microphone.delegate = self;
    [_scene addShape:_microphone.microphoneShape];
    _sceneDirty = YES;
    
}

- (void)simulationBodyChanged:(SimulationBody *)simulationBody {
    // Needs intersection update
    simulationBody->dirty = YES;
    _sceneDirty = YES;
}

- (void)simulationMicChanged:(SimulationMicrophone *)simulationMicrophone {
    simulationMicrophone->dirty = YES;
    _sceneDirty = YES;
}

- (void)updateSimulation:(id)sender {
    if (!_sceneDirty) {
        return;
    }
    
    if (_microphone == nil) {
        return;
    }
    
    if (_microphone->dirty) {
        [_microphone updatePoints];
    }
    
    // Check each body
    for (SimulationBody *body in _bodies) {
        if (body->dirty) {
            [body updatePoints];
        }
        
        initPolyWithPoints(&_intersection, NULL, 0);
        gpc_polygon_clip(GPC_INT, &body->poly, &_microphone->poly, &_intersection);
        
        gpc_free_tristrip(&body->intersectionArea);

        if (_intersection.contour != NULL) {
            gpc_polygon_to_tristrip(&_intersection, &body->intersectionArea);
            
            // Calculate the area
            float area = 0.0;
            for (int i = 0 ; i < body->intersectionArea.num_strips ; i++)
            {
                for (int j = 0 ; j < body->intersectionArea.strip[i].num_vertices-2 ; j++) {
                NSPoint a = NSMakePoint(body->intersectionArea.strip[i].vertex[j].x,body->intersectionArea.strip[i].vertex[j].y);
                NSPoint b = NSMakePoint(body->intersectionArea.strip[i].vertex[j+1].x,body->intersectionArea.strip[i].vertex[j+1].y);
                NSPoint c = NSMakePoint(body->intersectionArea.strip[i].vertex[j+2].x,body->intersectionArea.strip[i].vertex[j+2].y);
                area += fabs(a.x*(b.y-c.y) + b.x*(c.y-a.y) + c.x*(a.y-b.y))/2.0;
                }
            }
            
            NSLog(@"got intersection area %f", area);
        }
        
        gpc_free_polygon(&_intersection);
    }
    
    
    _sceneDirty = false;
    
}

- (void)addBody:(BodyEntity *)entity {
    // Shape
    SimulationBody *body = [[SimulationBody alloc] initWithBody:entity];
    body.delegate = self;
    _bodies = [_bodies arrayByAddingObject:body];
    
    [_scene addShape:body.fieldShape];
    
    _sceneDirty = YES;
}

- (void)removeShape:(id<Shape>)shape {
    for (SimulationBody* body in _bodies) {
        if (body.fieldShape == shape) {
            body.delegate = nil;
            [body.body.managedObjectContext deleteObject:body.body];
            [_scene removeShape:body.fieldShape];
            NSMutableArray *newBodies = [NSMutableArray arrayWithArray:_bodies];
            [newBodies removeObject:body];
            _bodies = [NSArray arrayWithArray:newBodies];
            return;
        }
    }
    
    _sceneDirty = YES;
}
@end
