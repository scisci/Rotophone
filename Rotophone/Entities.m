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

@dynamic anchorX;
@dynamic anchorY;
@dynamic originX;
@dynamic originY;
@dynamic rotation;

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
