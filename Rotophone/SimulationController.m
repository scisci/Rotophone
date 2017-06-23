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
#import "PdFile.h"
#import "PdBase.h"
#import "MicrophonePerformer.h"


static void* SimBodyKVOContext = &SimBodyKVOContext;
static void* SimBodyWeightKVOContext = &SimBodyWeightKVOContext;
static void* SimBodyPanKVOContext = &SimBodyPanKVOContext;

static void* SimMicKVOContext = &SimMicKVOContext;

static float triStripArea(gpc_tristrip* ts) {
    float area = 0.0;
    for (int i = 0 ; i < ts->num_strips ; i++)
    {
        for (int j = 0 ; j < ts->strip[i].num_vertices-2 ; j++) {
            NSPoint a = NSMakePoint(ts->strip[i].vertex[j].x,ts->strip[i].vertex[j].y);
            NSPoint b = NSMakePoint(ts->strip[i].vertex[j+1].x,ts->strip[i].vertex[j+1].y);
            NSPoint c = NSMakePoint(ts->strip[i].vertex[j+2].x,ts->strip[i].vertex[j+2].y);
            area += fabs(a.x*(b.y-c.y) + b.x*(c.y-a.y) + c.x*(a.y-b.y))/2.0;
        }
    }
    return area;
}

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
    gpc_polygon polyLeft;
    gpc_polygon polyRight;
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
        
        initPolyWithPoints(&polyLeft, &points[0], numPoints);
        initPolyWithPoints(&polyRight, &points[0], numPoints);
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
    
    float micDist = _microphoneShape.pickupDist;
    float micAngle = _microphoneShape.pickupAngle * 0.5;
    
    float xOffset1 = cosf(micAngle) * micDist;
    float yOffset1 = sinf(micAngle) * micDist;
    
    float xOffset2 = cosf(-micAngle) * micDist;
    float yOffset2 = sinf(-micAngle) * micDist;
    // Transform each point
    int numPointsLeft = 3;
    NSPoint pointsLeft[] = {NSMakePoint(0,0), NSMakePoint(xOffset2, yOffset2), NSMakePoint(micDist, 0)};//NSMakePoint(xOffset2,yOffset2)};
    for (int i = 0; i < numPointsLeft; i++) {
        NSPoint tp = [transform transformPoint:pointsLeft[i]];
        polyLeft.contour[0].vertex[i].x = tp.x;
        polyLeft.contour[0].vertex[i].y = tp.y;
    }
    
    int numPointsRight = 3;
    NSPoint pointsRight[] = {NSMakePoint(0,0), NSMakePoint(xOffset1, yOffset1), NSMakePoint(micDist, 0)};
    for (int i = 0; i < numPointsRight; i++) {
        NSPoint tp = [transform transformPoint:pointsRight[i]];
        polyRight.contour[0].vertex[i].x = tp.x;
        polyRight.contour[0].vertex[i].y = tp.y;
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
    gpc_free_polygon(&polyLeft);
    gpc_free_polygon(&polyRight);
}
@end




@interface SimulationBody : NSObject {
    @public
    gpc_polygon poly;
    gpc_tristrip intersectionAreaLeft;
    gpc_tristrip intersectionAreaRight;
    BOOL dirty;
    PerformanceTarget* target;
    float _lastScanParam;
}


@property (unsafe_unretained) id<SimulationBodyDelegate> delegate;
@property (retain) FieldEntity* field;
@property (retain) BodyEntity* body;
@property (retain) FieldShapeAdapter* fieldShape;
@property (readonly) float area;
@property (readwrite) float intersectionAreaLeft;
@property (readwrite) float intersectionAreaRight;
@property (readonly) float parameterizedIntersection;

@end

@implementation SimulationBody

@synthesize intersectionAreaLeft = _intersectionAreaLeft;
@synthesize intersectionAreaRight = _intersectionAreaRight;


- (id) initWithBody:(BodyEntity *)body {
    if (self = [super init]) {
        self.body = body;
        self.field = [[body.fields allObjects] objectAtIndex:0];
        
        target = [[PerformanceTarget alloc] init];
        
        // TODO: listen to changes to the body
        self.fieldShape = [[FieldShapeAdapter alloc] initWithBody:body AndField:_field];
        
        [_fieldShape addObserver:self forKeyPath:@"shapeChanged" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimBodyKVOContext];
        [_field addObserver:self forKeyPath:@"pan" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimBodyPanKVOContext];
        
        [_body addObserver:self forKeyPath:@"weight" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SimBodyWeightKVOContext];

        
        int numPoints = 4;
        NSPoint points[] = {NSMakePoint(0,0), NSMakePoint(0, 10), NSMakePoint(10,10), NSMakePoint(10, 0)};
        
            initPolyWithPoints(&poly, &points[0], numPoints);
        intersectionAreaLeft.strip = NULL;
        intersectionAreaLeft.num_strips = 0;
        intersectionAreaRight.strip = NULL;
        intersectionAreaRight.num_strips = 0;

        dirty = YES;
    }
    return self;
}
- (float)area {
    return _field.width.floatValue * _field.height.floatValue;
}

- (float)scanParam {
    if ((_intersectionAreaLeft == 0 && _intersectionAreaRight == 0) || self.area == 0) {
        return _lastScanParam;
    }
    
    _lastScanParam = (_intersectionAreaLeft / (_intersectionAreaLeft + _intersectionAreaRight));
    return _lastScanParam;
}

- (float)centerScanParam {
    float param = [self scanParam];
    float p = (1.0 - 2.0 * fabsf(0.5 - param)); // 0 - 1 where  1 is in center
    
    p *= 2.5;
    if (p > 1.0) {
        p = 1.0;
    }
    
    return p;
}

- (float)parameterizedIntersection {
    float a = self.area;
    if (a <= 0) {
        return 0;
    }
    
    float p = (_intersectionAreaLeft + _intersectionAreaRight) / a;
    p *= _body.weight.floatValue;
    if (p < 0) {
        p = 0;
    } else if (p > 1) {
        p = 1;
    }
    return p * 1.25;
}

- (float)parameterizedPan {
    if ((_intersectionAreaLeft == 0 && _intersectionAreaRight == 0) || self.area == 0) {
        return 0.5;
    }
    
    // Use this if you want to base pan of the idea of a stereo mic
    //float panParam = 1.0 - (_intersectionAreaLeft / (_intersectionAreaLeft + _intersectionAreaRight));
    
    
    return _field.pan.floatValue;
    //return panParam;
}

- (float)freq1 {
    if ([_body.name isEqualToString:@"p1"]) {
        return 77.78;
    } else if ([_body.name isEqualToString:@"p2"]) {
        return 58.27;
    } else if ([_body.name isEqualToString:@"p3"]) {
        return 196.0;
    }
    
    return 155.56;
}

- (float)freq2 {
    if ([_body.name isEqualToString:@"p1"]) {
        return 466.16;
    } else if ([_body.name isEqualToString:@"p2"]) {
        return 5587.65;
    } else if ([_body.name isEqualToString:@"p3"]) {
        return 233.08;
    }
    
    return 466.16;
}

- (float)freq3 {
    if ([_body.name isEqualToString:@"p1"]) {
        return 1318.51;
    } else if ([_body.name isEqualToString:@"p2"]) {
        return 12543.84;
    } else if ([_body.name isEqualToString:@"p3"]) {
        return 2349.32;
    }
    
    return 466.16;
}

- (float)freq1Param {
    return [self freq1];// * ([self centerScanParam] + 1.0);
}

- (float)freq2Param {
    return [self freq2];// * ([self centerScanParam] + 1.0);// * 0.618;
}

- (float)freq3Param {
    return [self freq3];// * ([self centerScanParam] + 1.0);// * 1.618;
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

- (void)updateTargets:(SimulationMicrophone *)microphone {
    // We compare
    gpc_vertex micOrigin = microphone->polyLeft.contour[0].vertex[0];
    
    int numPoints = 4;
    target.angleMin = CGFLOAT_MAX;
    target.angleMax = -CGFLOAT_MAX;
    float angles[4];
    for (int i = 0; i < numPoints;i++) {
        gpc_vertex tp = poly.contour[0].vertex[i];
        float dx = tp.x - micOrigin.x;
        float dy = tp.y - micOrigin.y;
        
        angles[i] = 2 * M_PI - atan2f(dy, dx) + microphone.microphoneShape.rotation;
        /*
        if (angles[i] < 0) {
            angles[i] += 2 * M_PI;
        }
         */
        
        // Angle is in range -PI to PI
        
        for (int j = 0; j < i; j++) {
            float dif = angles[i] - angles[j];
            if (dif >= M_PI) {
                angles[i] -= 2 * M_PI;
            } else if (dif <= -M_PI) {
                angles[i] += 2 * M_PI;
            }
        }
        
        if (angles[i] < target.angleMin) {
            target.angleMin = angles[i];
        }
        
        if (angles[i] > target.angleMax) {
            target.angleMax = angles[i];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SimBodyKVOContext || context == SimBodyWeightKVOContext || context == SimBodyPanKVOContext) {
        if (_delegate != nil) {
            // Update our points
            if (context == SimBodyKVOContext) {
                dirty = YES;
            }
            
            if (context == SimBodyPanKVOContext) {
                [_delegate simulationBodyMixerChanged:self];
            } else {
                [_delegate simulationBodyChanged:self];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [_fieldShape removeObserver:self forKeyPath:@"shapeChanged"];
    [_body removeObserver:self forKeyPath:@"weight"];
    [_field removeObserver:self forKeyPath:@"pan"];
    gpc_free_polygon(&poly);
    gpc_free_tristrip(&intersectionAreaLeft);
    gpc_free_tristrip(&intersectionAreaRight);
}
@end


@interface SimulationController () {
    NSArray* _bodies;
    PdFile *_patch;
    SimulationMicrophone* _microphone;
    NSTimer* _simulationTimer;
    gpc_polygon _intersection;
    MicrophonePerformer *_performer;
    BOOL _performing;
    BOOL _started;
    BOOL _sceneDirty;
    BOOL _mixerDirty;
    float _lastPosition;
    NSDate *_lastUpdate;
    
}

@end

@implementation SimulationController
@synthesize scene = _scene;
- (id)initWithPatch:(PdFile *)patch {
    if (self = [super init]) {
        _patch = patch;
        _bodies = [[NSArray alloc] init];
        _started = NO;
        _performing = NO;
        _intersection.contour = NULL;
        _intersection.hole = NULL;
        _intersection.num_contours = 0;
        _lastPosition = 0;
        _lastUpdate = nil;
        _performer = [[MicrophonePerformer alloc] init];
        _sceneDirty = true;
        _mixerDirty = true;
        
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
    if (_started) {
        return;
    }

    _started = YES;
    
    // Update simulation 24fps, this matches with the interpolator in the pd file
    _simulationTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval: 0.05
                                                  target: self
                                                selector: @selector(updateSimulation:)
                                                userInfo: nil
                                                 repeats: YES];
    [[NSRunLoop currentRunLoop] addTimer:_simulationTimer forMode:NSRunLoopCommonModes];
    
    [self updatePerformState];
}

- (void)drawDebugGraphics {
    // Draw all of the intersections
    if (_microphone == nil) {
        return;
    }

    for (SimulationBody *body in _bodies) {
        for (int i = 0 ; i < body->intersectionAreaLeft.num_strips ; i++)
        {
            NSBezierPath *path = [NSBezierPath bezierPath];
            for (int j = 0 ; j < body->intersectionAreaLeft.strip[i].num_vertices-2 ; j++) {
                [path moveToPoint:NSMakePoint(body->intersectionAreaLeft.strip[i].vertex[j].x,body->intersectionAreaLeft.strip[i].vertex[j].y)];
                [path lineToPoint:NSMakePoint(body->intersectionAreaLeft.strip[i].vertex[j+1].x,body->intersectionAreaLeft.strip[i].vertex[j+1].y)];
                [path lineToPoint:NSMakePoint(body->intersectionAreaLeft.strip[i].vertex[j+2].x,body->intersectionAreaLeft.strip[i].vertex[j+2].y)];
            
            }
            [[NSColor brownColor] set];
            [path fill];
        }
        
        for (int i = 0 ; i < body->intersectionAreaRight.num_strips ; i++)
        {
            NSBezierPath *path = [NSBezierPath bezierPath];
            for (int j = 0 ; j < body->intersectionAreaRight.strip[i].num_vertices-2 ; j++) {
                [path moveToPoint:NSMakePoint(body->intersectionAreaRight.strip[i].vertex[j].x,body->intersectionAreaRight.strip[i].vertex[j].y)];
                [path lineToPoint:NSMakePoint(body->intersectionAreaRight.strip[i].vertex[j+1].x,body->intersectionAreaRight.strip[i].vertex[j+1].y)];
                [path lineToPoint:NSMakePoint(body->intersectionAreaRight.strip[i].vertex[j+2].x,body->intersectionAreaRight.strip[i].vertex[j+2].y)];
                
            }
            [[NSColor purpleColor] set];
            [path fill];
        }
    }
}

- (void)stop {
    if (!_started) {
        return;
    }
    
    _started = NO;
    
    [_simulationTimer invalidate];
    _simulationTimer = nil;
    
    [self updatePerformState];
}


- (void)startPerform {
    _performing = YES;
    [self updatePerformState];
   
}

- (void)stopPerform {
    _performing = NO;
    [self updatePerformState];
}

- (void)updatePerformState {
    if (_performing && _started) {
        [_performer start];
    } else {
        [_performer stop];
    }
}


- (void)addMicrophone:(NSObject<MicrophoneProxy> *)proxy {
    if (_microphone != nil) {
        NSLog(@"oops don't set multiple microphones!");
    }
    _microphone = [[SimulationMicrophone alloc] initWithMicrophoneProxy:proxy];
    _microphone.delegate = self;
    
    _performer.microphone = proxy;
    
    [_scene addShape:_microphone.microphoneShape];
    _sceneDirty = YES;
    
}

- (void)simulationBodyChanged:(SimulationBody *)simulationBody {
    // Needs intersection update
    simulationBody->dirty = YES;
    _sceneDirty = YES;
}

- (void)simulationBodyMixerChanged:(SimulationBody *)simulationBody {
    _mixerDirty = YES;
}

- (void)simulationMicChanged:(SimulationMicrophone *)simulationMicrophone {
    simulationMicrophone->dirty = YES;
    _sceneDirty = YES;
}

- (void)updateSimulation:(id)sender {
    
    if (_microphone == nil) {
        return;
    }
    
    
    bool velocityValid = false;
    double velocity = 0.0;
    NSTimeInterval elapsed = -[_lastUpdate timeIntervalSinceNow];
    if (elapsed < 1.5) {
        double dist = _microphone.microphoneShape.microphoneRotation - _lastPosition;
        if (dist > M_PI) {
            dist -= 2 * M_PI;
        } else if (dist < -M_PI) {
            dist += 2 * M_PI;
        }
        
        if (fabs(dist) > 0.0) {
            _lastUpdate = [NSDate date];
            _lastPosition = _microphone.microphoneShape.microphoneRotation;
            velocity = dist / elapsed;
            velocityValid = true;
        }
        
        
        
        
    } else {
        _lastUpdate = [NSDate date];
        _lastPosition = _microphone.microphoneShape.microphoneRotation;
    }
    
    if (_microphone->dirty) {
        [_microphone updatePoints];
    }
    
    if (_performer != nil) {
        [_performer updatePosition:_lastPosition andVelocity:velocity andValid:velocityValid];
    }
    
    if (_sceneDirty) {
        // Check each body
        for (SimulationBody *body in _bodies) {
            if (body->dirty) {
                [body updatePoints];
                
                // Update the targets
                [body updateTargets:_microphone];
            }
            
            initPolyWithPoints(&_intersection, NULL, 0);
            
            gpc_polygon_clip(GPC_INT, &body->poly, &_microphone->polyLeft, &_intersection);
            gpc_free_tristrip(&body->intersectionAreaLeft);
            if (_intersection.contour != NULL) {
                gpc_polygon_to_tristrip(&_intersection, &body->intersectionAreaLeft);
                body.intersectionAreaLeft = triStripArea(&body->intersectionAreaLeft);
            } else {
                body.intersectionAreaLeft = 0.0;
            }
            
            gpc_free_polygon(&_intersection);
            
            
            
            initPolyWithPoints(&_intersection, NULL, 0);
            
            gpc_polygon_clip(GPC_INT, &body->poly, &_microphone->polyRight, &_intersection);
            gpc_free_tristrip(&body->intersectionAreaRight);
            if (_intersection.contour != NULL) {
                gpc_polygon_to_tristrip(&_intersection, &body->intersectionAreaRight);
                body.intersectionAreaRight = triStripArea(&body->intersectionAreaRight);
                
            } else {
                body.intersectionAreaRight = 0.0;
            }
            
            gpc_free_polygon(&_intersection);
        }
        
        // Update pd
        [self updatePD];
    }
    
    if (_mixerDirty) {
        [self updateMixer];
    }
    
    _mixerDirty = false;
    _sceneDirty = false;
    
}

- (void) updatePD {
    for (SimulationBody *body in _bodies) {
        NSString *paramName = [NSString stringWithFormat:@"%d-%@", _patch.dollarZero, body.body.name];
        NSString *panName = [NSString stringWithFormat:@"%d-%@_pan", _patch.dollarZero, body.body.name];
        NSString *f1Name = [NSString stringWithFormat:@"%d-%@_f1", _patch.dollarZero, body.body.name];
        NSString *f2Name = [NSString stringWithFormat:@"%d-%@_f2", _patch.dollarZero, body.body.name];
        NSString *f3Name = [NSString stringWithFormat:@"%d-%@_f3", _patch.dollarZero, body.body.name];
        int result = [PdBase sendFloat:body.parameterizedIntersection toReceiver:paramName];
        result = [PdBase sendFloat:body.parameterizedPan toReceiver:panName];
        result = [PdBase sendFloat:[body freq1Param] toReceiver:f1Name];
        result = [PdBase sendFloat:[body freq2Param] toReceiver:f2Name];
        result = [PdBase sendFloat:[body freq3Param] toReceiver:f3Name];
    }
}



- (void)updateMixer {
    for (SimulationBody *body in _bodies) {
        NSString *paramName = [NSString stringWithFormat:@"%d-%@_pan", _patch.dollarZero, body.body.name];
        [PdBase sendFloat:body.field.pan.floatValue toReceiver:paramName];
    }
}

- (void)addBody:(BodyEntity *)entity {
    // Shape
    SimulationBody *body = [[SimulationBody alloc] initWithBody:entity];
    body.delegate = self;
    _bodies = [_bodies arrayByAddingObject:body];
    
    [_scene addShape:body.fieldShape];
    
    _sceneDirty = YES;
    
    [_performer addTarget:body->target];
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
            [_performer removeTarget:body->target];
            return;
        }
    }
    
    _sceneDirty = YES;
}
@end
