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

+ (NSFetchRequest *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"MicrophoneEntity"];
}

@dynamic embeddedData;
@dynamic name;
@dynamic rotoID;
@dynamic rotoPosition;

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

+ (NSFetchRequest *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"SerialPortEntity"];
}

@dynamic name;
@dynamic path;

@end
