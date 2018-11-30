//
//  Entities.h
//  Rotophone
//
//  Created by z on 5/29/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#ifndef Entities_h
#define Entities_h

#import <CoreData/CoreData.h>
/*
// Keep older versions of the compiler happy
#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
//#define nullable
#define nonnullable
#endif

#ifndef nullable
#define nullable
#endif

#ifndef __nullable
#define __nullable
#endif
*/

@interface MicrophoneEntity : NSManagedObject
+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context;
- (id _Nonnull )initWithName:(NSString *_Nonnull)name andContext:(NSManagedObjectContext *_Nonnull)context;

@property (nullable, nonatomic, retain) NSData *embeddedData;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *rotoPosition;
@property (nullable, nonatomic, retain) NSNumber *rotoTarget;
@property (nullable, nonatomic, retain) NSNumber *rotoID;

@property (nullable, nonatomic, retain) NSNumber *anchorX;
@property (nullable, nonatomic, retain) NSNumber *anchorY;
@property (nullable, nonatomic, retain) NSNumber *originX;
@property (nullable, nonatomic, retain) NSNumber *originY;
@property (nullable, nonatomic, retain) NSNumber *rotation;
@property (nullable, nonatomic, retain) NSNumber *pickupAngle;
@property (nullable, nonatomic, retain) NSNumber *pickupDist;
@end


@interface FieldEntity : NSManagedObject
+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context;
- (id _Nonnull )initWithName:(NSString *_Nonnull)name andContext:(NSManagedObjectContext *_Nonnull)context;

@property (nullable, nonatomic, retain) NSString *name;

@property (nullable, nonatomic, retain) NSNumber *width;
@property (nullable, nonatomic, retain) NSNumber *height;

@property (nullable, nonatomic, retain) NSNumber *anchorX;
@property (nullable, nonatomic, retain) NSNumber *anchorY;
@property (nullable, nonatomic, retain) NSNumber *originX;
@property (nullable, nonatomic, retain) NSNumber *originY;
@property (nullable, nonatomic, retain) NSNumber *rotation;
@property (nullable, nonatomic, retain) NSNumber *pan;

@end


@interface SceneEntity : NSManagedObject
+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context;
- (id _Nonnull )initWithContext:(NSManagedObjectContext *_Nonnull)context;

@property (nullable, nonatomic, retain) NSNumber *tX;
@property (nullable, nonatomic, retain) NSNumber *tY;
@property (nullable, nonatomic, retain) NSNumber *scale;
@end


@interface BodyEntity : NSManagedObject
+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context;
- (id _Nonnull )initWithName:(NSString *_Nonnull)name andContext:(NSManagedObjectContext *_Nonnull)context;

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *weight;

@property (nullable, nonatomic, retain) NSSet *fields;
@end



@interface SerialPortEntity : NSManagedObject
+ (NSFetchRequest *_Nonnull)fetchRequestInContext:(NSManagedObjectContext *_Nonnull)context;
- (id _Nonnull )initWithName:(NSString *_Nonnull)name Path:(NSString *_Nonnull)path andContext:(NSManagedObjectContext *_Nonnull)context;

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *path;
@end


#endif /* Entities_h */
