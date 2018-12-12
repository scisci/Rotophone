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
#import "SimulationComposition.h"
#import "AudioMidiSettingsManager.h"

enum SimBodyType {
  kSimBodyTypeSample,
  kSimBodyTypeVideoChannel,
  kSimBodyTypeMidiChannel
};

struct SimBodyMapping {
  enum SimBodyType type;
  int video_channel;
  int midi_channel;
};


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


@interface GrainController : NSObject {
    PdFile *_patch;
    NSString *_sampleNumberParamName;
    NSString *_gainDBParamName;
    NSString *_muteParamName;
    NSString *_jitterParamName;
    NSString *_samplePosParamName;
    
    NSString *_voicesParamName;
    NSString *_scanSpeedParamName;
    NSString *_sustainParamName;
    NSString *_asynchParamName;
    NSString *_envelopeParamName;
    
    NSString *_spreadParamName;
    NSString *_panParamName;
    NSString *_envelopeSpreadParamName;
    NSString *_sustainSpreadParamName;
    float _volume;
}

@end


@implementation GrainController

- (float)volume {
    return _volume;
}
- (id)initWithPatch:(PdFile *)patch {
    if (self = [super init]) {
        _patch = patch;
        
        _sampleNumberParamName = [NSString stringWithFormat:@"%d-zample_idx_number", _patch.dollarZero];
        _gainDBParamName = [NSString stringWithFormat:@"%d-grangain_db", _patch.dollarZero];
        _muteParamName = [NSString stringWithFormat:@"%d-granmute", _patch.dollarZero];
        
        _jitterParamName = [NSString stringWithFormat:@"%d-zample_jitter", _patch.dollarZero];
        _samplePosParamName = [NSString stringWithFormat:@"%d-zample_pos", _patch.dollarZero];
        
        _voicesParamName = [NSString stringWithFormat:@"%d-zample_voices", _patch.dollarZero];
        _scanSpeedParamName = [NSString stringWithFormat:@"%d-zample_scan_speed", _patch.dollarZero];
        _sustainParamName = [NSString stringWithFormat:@"%d-zample_sustain_min", _patch.dollarZero];
        _asynchParamName = [NSString stringWithFormat:@"%d-zample_asynch", _patch.dollarZero];
        _envelopeParamName = [NSString stringWithFormat:@"%d-zample_envelope_min", _patch.dollarZero];
        _spreadParamName = [NSString stringWithFormat:@"%d-zample_spread", _patch.dollarZero];
        _panParamName = [NSString stringWithFormat:@"%d-zample_pan", _patch.dollarZero];
        _envelopeSpreadParamName = [NSString stringWithFormat:@"%d-zample_envelope_spread", _patch.dollarZero];
        _sustainSpreadParamName = [NSString stringWithFormat:@"%d-zample_sustain_spread", _patch.dollarZero];
        
        _volume = 0;
        
        int result = 0;
        result = [PdBase sendFloat:0 toReceiver:_gainDBParamName];
        result = [PdBase sendFloat:1 toReceiver:_muteParamName];
        
        [self enterScanMode];
    }
    
    return self;
}


- (void)enterScanMode {
    int result = 0;
    result = [PdBase sendFloat:270 toReceiver:_jitterParamName]; // 0 - 500
    result = [PdBase sendFloat:30 toReceiver:_voicesParamName]; // 1-32
    result = [PdBase sendFloat:40 toReceiver:_scanSpeedParamName]; // 0 - 10,000 ?
    result = [PdBase sendFloat:800 toReceiver:_sustainParamName]; // 0 - 5000
    result = [PdBase sendFloat:0 toReceiver:_asynchParamName]; // 99 - 0
    result = [PdBase sendFloat:100 toReceiver:_envelopeParamName]; // 2 - 200
    result = [PdBase sendFloat:250 toReceiver:_spreadParamName]; // 0 - 1000
    result = [PdBase sendFloat:20 toReceiver:_envelopeSpreadParamName]; // 0 - 50
    result = [PdBase sendFloat:35 toReceiver:_sustainSpreadParamName]; // 0 - 100
}

- (void)setSampleIndex:(int)index {
    if (index < 0 || index >= 8) {
        return;
    }
    
    int result = [PdBase sendFloat:index toReceiver:_sampleNumberParamName];
    if (result != 0) {
        NSLog(@"failed to set sample index");
    }
}

- (void)setVolumeParam:(float)volume {
    _volume = volume;
    int result = [PdBase sendFloat:_volume * 55.0 toReceiver:_gainDBParamName];
}


- (void)setPosition:(float)param AndPan:(float)pan {
    int result = [PdBase sendFloat:param * 1000 toReceiver:_samplePosParamName];
    if (result != 0) {
        NSLog(@"failed to set position");
    }
    result = [PdBase sendFloat:40 toReceiver:_scanSpeedParamName]; // 0 - 10,000 ?
    
    result =[PdBase sendFloat:pan * 120 toReceiver:_panParamName]; // 0 - 500
}

@end

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
  
    NSString *_mappingName;
    struct SimBodyMapping _mapping;
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

- (struct SimBodyMapping*)mapping {
  if (_mappingName == nil || ![_mappingName isEqualToString:_body.name]) {
    _mappingName = [_body.name copy];
    _mapping.type = kSimBodyTypeSample;
    _mapping.video_channel = -1;
    _mapping.midi_channel = -1;
    
    if ([_body.name hasPrefix:@"vch"]) {
      _mapping.type = kSimBodyTypeVideoChannel;
      _mapping.video_channel = [[_body.name substringFromIndex:3] intValue] - 1;
      if (_mapping.video_channel >= 0 && _mapping.video_channel < 16) {
        return &_mapping;
      }
    }
    
    if ([_body.name hasPrefix:@"mch"]) {
      _mapping.type = kSimBodyTypeMidiChannel;
      _mapping.midi_channel = [[self.body.name substringFromIndex:3] intValue] - 1;
      if (_mapping.midi_channel >= 0 && _mapping.midi_channel < 16) {
        return &_mapping;
      }
    }
    
    _mapping.type = kSimBodyTypeSample;
  }
  
  return &_mapping;
};



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
    //float panParam = ;
    
    
   // if ([_body.name characterAtIndex:0] == 'p') {
        return _field.pan.floatValue;
    //}
    //return panParam;
    
    //return 1.0 - (_intersectionAreaLeft / (_intersectionAreaLeft + _intersectionAreaRight));
}

- (float)freq1 {
    if ([_body.name isEqualToString:@"p1"]) {
        return 77.78;
    } else if ([_body.name isEqualToString:@"p2"]) {
        return 98.0;
    } else if ([_body.name isEqualToString:@"p3"]) {
        return 196.0;
    } else if ([_body.name isEqualToString:@"tv"]) {
        return 212.0;
    } else if ([_body.name isEqualToString:@"v1"]) {
        return 16388.0;
    } else if ([_body.name isEqualToString:@"v2"]) {
        return 3847.0;
    }
    
    return 155.56;
}

- (float)freq2 {
    if ([_body.name isEqualToString:@"p1"]) {
        return 466.16;
    } else if ([_body.name isEqualToString:@"p2"]) {
        return 87.31;
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
        angles[i] = fmodf(angles[i], 2 * M_PI);
        
        if (angles[i] < 0) {
            angles[i] += 2 * M_PI;
        }
        
        
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
    SimulationBody *_currentTarget;
    SimulationBody *_nextTarget;
    NSTimer* _targetDebounceTimer;
    NSDictionary* _sampleLookup;
    GrainController* _grain;
    MultiChannelAudioTrackMixer *_avMixer;
    MixerInput *_avMix;
    SimulationComposition *_simComp;
    MidiMixerInput *_midiMix;
    
    BOOL _targetSwapState;
    NSDate *_lastCompositionRefresh;
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
        _lastCompositionRefresh = [NSDate date];
        _performer = [[MicrophonePerformer alloc] init];
        _sceneDirty = true;
        _mixerDirty = true;
        _currentTarget = NULL;
        _avMixer = NULL;
        _avMix = NULL;
        _simComp = [[SimulationComposition alloc] initWithDelegate:self andFreqs:[NSArray arrayWithObjects: [NSNumber numberWithDouble: 77.78],
            [NSNumber numberWithDouble: 98.0],
            [NSNumber numberWithDouble: 196.0],
            [NSNumber numberWithDouble: 212.0],
            nil]];
        _midiMix = [[MidiMixerInput alloc] initWithNumChannels:2];

        _grain = [[GrainController alloc] initWithPatch:_patch];
        _sampleLookup = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:0],@"p1",
                          [NSNumber numberWithInt:1],@"tv",
                          [NSNumber numberWithInt:3],@"p2",
                          [NSNumber numberWithInt:3],@"p3",
                          [NSNumber numberWithInt:4],@"v1",
                          [NSNumber numberWithInt:5],@"v2",
                          [NSNumber numberWithInt:5],@"room1",
                          [NSNumber numberWithInt:6],@"room2",
                         nil];
        
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

- (void)setAVMixer:(MultiChannelAudioTrackMixer *)mixer
{
  _avMixer = mixer;
  _avMix = [mixer mix];
}

- (void)loadMidiResource:(URLResource *)resource
{
  NSString *path = [resource.url path];
  if (path != nil) {
    [_simComp loadMidiFile:path];
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
    
    [_grain enterScanMode];
    
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
    
    
    if (_targetDebounceTimer != nil) {
        [_targetDebounceTimer invalidate];
        _targetDebounceTimer = nil;
    }
    
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

- (int)sampleIndexForName:(NSString *)name {
    NSNumber* num = [_sampleLookup objectForKey:name];
    if (num != nil) {
        return (int)[num integerValue];
    }
    
    return -1;
}

- (void)fadeCurrentTarget {
    if (_targetDebounceTimer != nil) {
        [_targetDebounceTimer invalidate];
    }
    
    _targetDebounceTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:0.03 target:self selector:@selector(doFadeCurrentTarget:) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:_targetDebounceTimer forMode:NSRunLoopCommonModes];
}

- (void)doFadeCurrentTarget:(id)sender {
    if (_targetSwapState == 0) {
        float nextVolume = _grain.volume * 0.6;
        if (nextVolume < 0.05) {
            nextVolume = 0;
        }
        [_grain setVolumeParam:nextVolume];
        if (nextVolume == 0) {
            _targetSwapState = 1;
            [self updateCurrentTarget:nil];
        }
    } else if (_targetSwapState == 1) {
        float nextVolume = _grain.volume + (1 - _grain.volume) * 0.4;
        if (1 - _grain.volume < 0.05) {
            nextVolume = 1;
        }
        
        [_grain setVolumeParam:nextVolume];
        if (nextVolume == 1) {
            _targetSwapState = 2;
            [self updateCurrentTarget:nil];
        }
    } else {
        if (_targetDebounceTimer != nil) {
            [_targetDebounceTimer invalidate];
        }
    }
}



- (void)updateCurrentTarget:(id)sender {
    if (_targetDebounceTimer != nil) {
        [_targetDebounceTimer invalidate];
        _targetDebounceTimer = nil;
    }
    
    
    
     if (_targetSwapState == 0) {
         int sampleIndexCurrent = -1;
         int sampleIndexNext = -1;
         if (_currentTarget != nil) {
             sampleIndexCurrent = [self sampleIndexForName:_currentTarget.body.name];
         }
         
         if (_nextTarget != nil) {
             sampleIndexNext = [self sampleIndexForName:_nextTarget.body.name];
         }
        if (sampleIndexCurrent != sampleIndexNext) {
            NSLog(@"transitioning from %@", _currentTarget.body.name);
            // First fade down the volume
            [self fadeCurrentTarget];
            return;
        } else {
            _targetSwapState = 1;
        }
     }
    
        
    if (_targetSwapState == 1) {
        int sampleIndexCurrent = -1;
        int sampleIndexNext = -1;
        if (_currentTarget != nil) {
            sampleIndexCurrent = [self sampleIndexForName:_currentTarget.body.name];
        }
        
        if (_nextTarget != nil) {
            sampleIndexNext = [self sampleIndexForName:_nextTarget.body.name];
        }

        _currentTarget = _nextTarget;

        if (sampleIndexCurrent != sampleIndexNext) {
            NSLog(@"transitioned to %@", _currentTarget.body.name);
            [_grain setSampleIndex:sampleIndexNext];
            
            [self fadeCurrentTarget];
            
        } else {
            _targetSwapState = 2;
        }
    }
    
    if (_targetSwapState == 2) {
        NSLog(@"Transition complete.");
    }
}

- (void)updateSimulation:(id)sender {
    
    if (_microphone == nil) {
        return;
    }
    
    
    bool velocityValid = false;
    double velocity = 0.0;
    const NSTimeInterval elapsed = -[_lastUpdate timeIntervalSinceNow];
  
    if (-[_lastCompositionRefresh timeIntervalSinceNow] > 10.0) {
      _lastCompositionRefresh = [NSDate date];
      [_simComp refresh];
    }
  
    // If we haven't had an update within 1.5 seconds, maybe system was paused
    // so we treat that as a different case, i.e. we forget about the last
    // position and just start from scratch. In these cases the velocity is
    // invalid because we don't really know the last position.
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
  
    // Update the robot
    if (_performer != nil) {
        [_performer updatePosition:_lastPosition andVelocity:velocity andValid:velocityValid];
    }
  
    if (_simComp != nil) {
      [_simComp updatePosition:_lastPosition andVelocity:velocity andValid:velocityValid];
    }
  
    // Update the rendering and audio
    if (_sceneDirty) {
        // Check each body
        SimulationBody* maxTarget = nil;
        float maxTargetDist = CGFLOAT_MAX;
        
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
          
          // Find the object that is closest to the microphone angle
          // this only matters for sample objects
          struct SimBodyMapping* mapping = [body mapping];
          if (mapping->type == kSimBodyTypeSample) {
            float distMin = (body->target.angleMin - _microphone.microphoneShape.microphoneRotation);
            float distMax = (body->target.angleMax - _microphone.microphoneShape.microphoneRotation);
            if (distMin > M_PI) {
              distMin -= 2 * M_PI;
            } else if (distMin < -M_PI) {
              distMin += 2 * M_PI;
            }
            if (distMax > M_PI) {
              distMax -= 2 * M_PI;
            } else if (distMax < -M_PI) {
              distMax += 2 * M_PI;
            }
            
            if (fabs(distMin) < maxTargetDist) {
              maxTarget = body;
              maxTargetDist = fabs(distMin);
            }
            
            if (fabs(distMax) < maxTargetDist) {
              maxTarget = body;
              maxTargetDist = fabs(distMax);
            }
            
            
            // If this was the last closest target and selected as the current
            // target, then we should also animate the grain position
            if (body == _currentTarget && (body->target.angleMax != body->target.angleMin)) {
              float pos = (_microphone.microphoneShape.microphoneRotation - body->target.angleMin) / (body->target.angleMax - body->target.angleMin);
              if (pos < 0) {
                pos = 0;
              }
            
              [_grain setPosition:pos AndPan:[body parameterizedPan]];
            }
          }
        }
        
        
        if (maxTarget != _nextTarget) {
          _nextTarget = maxTarget;
          if (_targetDebounceTimer != nil) {
            [_targetDebounceTimer invalidate];
          }
          
          _targetSwapState = 0;
          
          _targetDebounceTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.25] interval:0.0 target:self selector:@selector(updateCurrentTarget:) userInfo:nil repeats:NO];
          
          [[NSRunLoop currentRunLoop] addTimer:_targetDebounceTimer forMode:NSRunLoopCommonModes];
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
  bool avChanged = false;
  bool midiChanged = false;
  for (SimulationBody *body in _bodies) {
    struct SimBodyMapping* mapping = [body mapping];
    switch (mapping->type) {
      case kSimBodyTypeVideoChannel:
        if (_avMix != NULL) {
          [_avMix setVolume:body.parameterizedIntersection * 0.75 forChannel:mapping->video_channel];
          avChanged = true;
        }
        break;
      case kSimBodyTypeMidiChannel:
        if (_midiMix != NULL) {
          if ([_midiMix setVolume:body.parameterizedIntersection * 0.75 forChannel:mapping->midi_channel]) {
            midiChanged = true;
          }
        }
        break;
      case kSimBodyTypeSample:
        {
        /*
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
          */
        }
        break;
    }
  }
  
  if (avChanged && _avMixer != nil) {
    [_avMixer setMix:_avMix];
  }
  
  if (midiChanged && _midiMix != nil) {
    [_simComp setMix:_midiMix];
  }
}



- (void)updateMixer {
  for (SimulationBody *body in _bodies) {
    struct SimBodyMapping* mapping = [body mapping];
    if (mapping->type == kSimBodyTypeSample) {
     // NSString *paramName = [NSString stringWithFormat:@"%d-%@_pan", _patch.dollarZero, body.body.name];
     // [PdBase sendFloat:body.field.pan.floatValue toReceiver:paramName];
    }
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



- (void)sendMidiData:(nonnull const unsigned char *)data ofSize:(size_t)dataSize {
  [[AudioMidiSettingsManager sharedManager] sendMidiData:data ofSize:dataSize];
}

@end
