//
//  DCTCoreDataStack.m
//  Convene
//
//  Created by Daniel Tull on 01.12.2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DCTCoreDataStack.h"

@interface DCTCoreDataStack ()
- (NSURL *)dctInternal_applicationDocumentsDirectory;
- (void)dctInternal_mainContextDidSave:(NSNotification *)notification;
- (void)dctInternal_saveManagedObjectContext:(NSManagedObjectContext *)context;
@end

@implementation DCTCoreDataStack {
	__strong NSManagedObjectContext *managedObjectContext;
	__strong NSManagedObjectModel *managedObjectModel;
	__strong NSPersistentStoreCoordinator *persistentStoreCoordinator;
	__strong NSString *modelName;
	__strong NSString *storeType;
	__strong NSManagedObjectContext *backgroundSavingContext;
}

@synthesize saveFailureHandler;

- (id)initWithModelName:(NSString *)name {
	return [self initWithModelName:name storeType:NSSQLiteStoreType];
}

- (id)initWithModelName:(NSString *)name storeType:(NSString *)type {
	
	if (!(self = [super init])) return nil;
	
	modelName = [name copy];
	storeType = [type copy];
	
	return self;
}

- (void)dctInternal_saveManagedObjectContext:(NSManagedObjectContext *)context {
	[context performBlock:^{
		NSError *error = nil;
		if (![context save:&error] && self.saveFailureHandler)
			self.saveFailureHandler(error);
	}];
}

- (void)dctInternal_mainContextDidSave:(NSNotification *)notification {
	[self dctInternal_saveManagedObjectContext:backgroundSavingContext];
}

- (void)save {
	[self dctInternal_saveManagedObjectContext:self.managedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext {
    
	if (managedObjectContext == nil) {
		
		NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
		if (coordinator != nil) {
			
			backgroundSavingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
			[backgroundSavingContext setPersistentStoreCoordinator:coordinator];
			
			managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
			[managedObjectContext setParentContext:backgroundSavingContext];
			
			[[NSNotificationCenter defaultCenter] addObserver:self 
													 selector:@selector(dctInternal_mainContextDidSave:)
														 name:NSManagedObjectContextDidSaveNotification
													   object:managedObjectContext];
		}
	}
	
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
		
	if (managedObjectModel == nil) {
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
		managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	}
	
	return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator == nil) {
		
		NSURL *storeURL = nil;
		
		if (![storeType isEqualToString:NSInMemoryStoreType]) {
			NSString *pathComponent = [NSString stringWithFormat:@"%@.sqlite", modelName];
			storeURL = [[self dctInternal_applicationDocumentsDirectory] URLByAppendingPathComponent:pathComponent];
		}
		
		NSError *error = nil;
		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		if (![persistentStoreCoordinator addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:nil error:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
    }
	
	return persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL *)dctInternal_applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
