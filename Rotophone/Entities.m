//
//  Entities.m
//  Rotophone
//
//  Created by z on 5/29/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>



#import "Entities.h"

@implementation MicrophoneEntity

- (id)initWithName:(NSString *)name andContext:(NSManagedObjectContext *)context {
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"MicrophoneEntity" inManagedObjectContext:context];
    if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
        self.name = name;
    }
    return self;
}

+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MicrophoneEntity" inManagedObjectContext:context];
    [request setEntity:entity];
    return request;
}

@dynamic embeddedData;
@dynamic name;
@dynamic rotoID;
@dynamic rotoPosition;
@dynamic rotoTarget;
@dynamic pickupAngle;
@dynamic pickupDist;

@dynamic anchorX;
@dynamic anchorY;
@dynamic originX;
@dynamic originY;
@dynamic rotation;

@end



@implementation FieldEntity

- (id)initWithName:(NSString *)name andContext:(NSManagedObjectContext *)context {
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"FieldEntity" inManagedObjectContext:context];
    if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
        self.name = name;
    }
    return self;
}

+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"FieldEntity" inManagedObjectContext:context];
    [request setEntity:entity];
    return request;
}

@dynamic name;
@dynamic width;
@dynamic height;

@dynamic anchorX;
@dynamic anchorY;
@dynamic originX;
@dynamic originY;
@dynamic rotation;

@end



@implementation SceneEntity

- (id)initWithContext:(NSManagedObjectContext *)context {
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"SceneEntity" inManagedObjectContext:context];
    if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
        self.tX = [NSNumber numberWithFloat:0.0];
        self.tY = [NSNumber numberWithFloat:0.0];
        self.scale = [NSNumber numberWithFloat:6.0];
    }
    return self;
}

+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SceneEntity" inManagedObjectContext:context];
    [request setEntity:entity];
    return request;
}

@dynamic tX;
@dynamic tY;
@dynamic scale;

@end



@implementation BodyEntity

- (id)initWithName:(NSString *)name andContext:(NSManagedObjectContext *)context {
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"BodyEntity" inManagedObjectContext:context];
    if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
        self.name = name;
    }
    return self;
}

+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"BodyEntity" inManagedObjectContext:context];
    [request setEntity:entity];
    return request;
}

@dynamic name;
@dynamic fields;

@end



@implementation SerialPortEntity

- (id)initWithName:(NSString *)name Path:(NSString *)path andContext:(NSManagedObjectContext *)context {
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"SerialPortEntity" inManagedObjectContext:context];
    if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
        self.name = name;
        self.path = path;
    }
    return self;
}

+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SerialPortEntity" inManagedObjectContext:context];
    [request setEntity:entity];
    return request;
}

@dynamic name;
@dynamic path;

@end
