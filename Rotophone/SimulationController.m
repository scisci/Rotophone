//
//  SimulationController.m
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SimulationController.h"

#import "MicrophoneShapeAdapter.h"
#import "FieldShapeAdapter.h"
#import "GPCPolygon.h"
#include "gpc.h"


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

@interface SimulationBody : NSObject {
    @public
    gpc_polygon poly;
}



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
        
        
        int numPoints = 4;
        NSPoint points[] = {NSMakePoint(0,0), NSMakePoint(0, 10), NSMakePoint(10,10), NSMakePoint(10, 0)};
        
            initPolyWithPoints(&poly, &points[0], numPoints);
    }
    return self;
}

- (void)dealloc {
    gpc_free_polygon(&poly);
}
@end


@interface SimulationController () {
    NSArray* _bodies;
    gpc_polygon _micPoly;
    gpc_polygon _intersection;
}

@end

@implementation SimulationController

- (id)init {
    if (self = [super init]) {
        _bodies = [[NSArray alloc] init];
        
        int numPoints = 3;
        NSPoint points[] = {NSMakePoint(0, 0), NSMakePoint(-5, 10), NSMakePoint(5, 10)};
        initPolyWithPoints(&_micPoly, &points[0], numPoints);
        
    }
    return self;
}

- (void)dealloc {
    gpc_free_polygon(&_micPoly);
}

- (void)addMicrophone:(NSObject<MicrophoneProxy> *)proxy {
    MicrophoneShapeAdapter* microphoneShape = [[MicrophoneShapeAdapter alloc] initWithProxy:proxy];
    
    [_scene addShape:microphoneShape];
    
}

- (void)addBody:(BodyEntity *)entity {
    // Shape
    SimulationBody *body = [[SimulationBody alloc] initWithBody:entity];
    
    _bodies = [_bodies arrayByAddingObject:body];
    
    [_scene addShape:body.fieldShape];
    
    // Intersect
    initPolyWithPoints(&_intersection, NULL, 0);
    gpc_polygon_clip(GPC_INT, &body->poly, &_micPoly, &_intersection);
    
    gpc_free_polygon(&_intersection);
}

- (void)removeShape:(id<Shape>)shape {
    for (SimulationBody* body in _bodies) {
        if (body.fieldShape == shape) {
            [body.body.managedObjectContext deleteObject:body.body];
            [_scene removeShape:body.fieldShape];
            NSMutableArray *newBodies = [NSMutableArray arrayWithArray:_bodies];
            [newBodies removeObject:body];
            _bodies = [NSArray arrayWithArray:newBodies];
            return;
        }
    }
}
@end
