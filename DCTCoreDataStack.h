//
//  DCTCoreDataStack.h
//  Convene
//
//  Created by Daniel Tull on 01.12.2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DCTCoreDataStack : NSObject

- (id)initWithModelName:(NSString *)modelName;
- (id)initWithModelName:(NSString *)modelName storeType:(NSString *)storeType;

@property(nonatomic, copy) NSDictionary *persistentStoreOptions;
@property(nonatomic, copy) NSString *modelConfiguration;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
