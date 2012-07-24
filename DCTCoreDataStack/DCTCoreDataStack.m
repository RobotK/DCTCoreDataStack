/*
 DCTCoreDataStack.m
 DCTCoreDataStack
 
 Created by Daniel Tull on 01.12.2011.
 
 
 
 Copyright (c) 2011 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DCTCoreDataStack.h"
#import <objc/runtime.h>

#ifdef TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface DCTCoreDataStack_ManagedObjectContext : NSManagedObjectContext
@end

@interface DCTCoreDataStack ()
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation DCTCoreDataStack {
	__strong NSManagedObjectContext *_managedObjectContext;
	__strong NSManagedObjectModel *managedObjectModel;
	__strong NSPersistentStoreCoordinator *persistentStoreCoordinator;
	__strong NSManagedObjectContext *_rootContext;
}

#pragma mark - NSObject

#ifdef TARGET_OS_IPHONE
- (void)dealloc {
	UIApplication *app = [UIApplication sharedApplication];
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter removeObserver:self
							 name:UIApplicationDidEnterBackgroundNotification
						   object:app];
	
	[defaultCenter removeObserver:self
							 name:UIApplicationWillTerminateNotification
						   object:app];
	
	[defaultCenter removeObserver:self
							 name:NSManagedObjectContextDidSaveNotification
						   object:_rootContext];
}
#endif

#pragma mark - Initialization

- (id)initWithStoreURL:(NSURL *)storeURL
			 storeType:(NSString *)storeType
		  storeOptions:(NSDictionary *)storeOptions
	modelConfiguration:(NSString *)modelConfiguration
			  modelURL:(NSURL *)modelURL {
	
	NSParameterAssert(storeURL);
	NSParameterAssert(storeType);
	
	if (!(self = [self init])) return nil;
	
	_storeURL = [storeURL copy];
	_storeType = [storeType copy];
	_storeOptions = [storeOptions copy];
	_modelURL = [modelURL copy];
	_modelConfiguration = [modelConfiguration copy];
	
	self.didResolvePersistentStoreErrorHandler = ^(NSError *error) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
		return NO;
	};
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	
#ifdef TARGET_OS_IPHONE
	
	UIApplication *app = [UIApplication sharedApplication];
	
	[defaultCenter addObserver:self
					  selector:@selector(dctInternal_applicationDidEnterBackgroundNotification:)
						  name:UIApplicationDidEnterBackgroundNotification
						object:app];
	
	[defaultCenter addObserver:self
					  selector:@selector(dctInternal_applicationWillTerminateNotification:)
						  name:UIApplicationWillTerminateNotification
						object:app];
#endif
	
	_rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[_rootContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	_rootContext.dct_name = @"DCTCoreDataStack.internal_rootContext";
	[defaultCenter addObserver:self
					  selector:@selector(_rootContextDidSaveNotification:)
						  name:NSManagedObjectContextDidSaveNotification
						object:_rootContext];
	
	return self;
}

- (id)initWithStoreFilename:(NSString *)filename {
	NSURL *storeURL = [[[self class] dctInternal_applicationDocumentsDirectory] URLByAppendingPathComponent:filename];
	return [self initWithStoreURL:storeURL
						storeType:NSSQLiteStoreType
					 storeOptions:nil
			   modelConfiguration:nil
						 modelURL:nil];
}

#pragma mark - Getters

- (void)_rootContextDidSaveNotification:(NSNotification *)notification {
	[self.managedObjectContext performBlock:^{
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
	}];
}

- (NSManagedObjectContext *)newWorkerManagedObjectContext {
	return [self _loadManagedObjectContextWithName:@"DCTCoreDataStack.workerContext"
								   concurrencyType:NSPrivateQueueConcurrencyType];
}

- (NSManagedObjectContext *)managedObjectContext {
    
	if (_managedObjectContext == nil)
		_managedObjectContext = [self _loadManagedObjectContextWithName:@"DCTCoreDataStack.mainContext" concurrencyType:NSMainQueueConcurrencyType];
	
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	
	if (managedObjectModel == nil)
		[self dctInternal_loadManagedObjectModel];
	
	return managedObjectModel;
}

#pragma mark - Internal Loading

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
	if (persistentStoreCoordinator == nil)
		[self dctInternal_loadPersistentStoreCoordinator];
	
	return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)_loadManagedObjectContextWithName:(NSString *)name
											  concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType {
		
	if ([NSManagedObjectContext instancesRespondToSelector:@selector(initWithConcurrencyType:)]) {
		NSManagedObjectContext *managedObjectContext = [[DCTCoreDataStack_ManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
		[managedObjectContext setParentContext:_rootContext];
		managedObjectContext.dct_name = name;
		return managedObjectContext;
	}
	
	NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
	[managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	managedObjectContext.dct_name = name;
	return managedObjectContext;
}

- (void)dctInternal_loadManagedObjectModel {
	
    if (self.modelURL) {
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
    } else {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]];
    }
}

- (void)dctInternal_loadPersistentStoreCoordinator {
	
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	
	NSError *error = nil;
	NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:self.storeType
																				  configuration:self.modelConfiguration
																							URL:self.storeURL
																						options:self.storeOptions
																						  error:&error];
	
	if (!persistentStore && self.didResolvePersistentStoreErrorHandler) {
		
		if (self.didResolvePersistentStoreErrorHandler(error))
			[persistentStoreCoordinator addPersistentStoreWithType:self.storeType
													 configuration:self.modelConfiguration
															   URL:self.storeURL
														   options:self.storeOptions
															 error:NULL];
	}
}

#pragma mark - Other Internal

+ (NSURL *)dctInternal_applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#ifdef TARGET_OS_IPHONE
- (void)dctInternal_applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	
	NSManagedObjectContext *context = self.managedObjectContext;
	
	if (![context hasChanges]) return;
	
	if ([context respondsToSelector:@selector(performBlock:)]) {
        
		[context performBlock:^{
			[context dct_saveWithCompletionHandler:self.automaticSaveCompletionHandler];
		}];
        
	} else {
		
		[context dct_saveWithCompletionHandler:self.automaticSaveCompletionHandler];
	}
	
	// TODO: what if there was a save error?
}

- (void)dctInternal_applicationWillTerminateNotification:(NSNotification *)notification {
	
	NSManagedObjectContext *context = self.managedObjectContext;
	
	if (![context hasChanges]) return;
	
	__block BOOL success = NO;
	__block NSError *error = nil;
	
	if ([context respondsToSelector:@selector(performBlock:)]
		) {
		
		[context performBlock:^{
			success = [context save:&error];
		}];
		
	} else {
		
		success = [context save:&error];
	}
	
	if (self.automaticSaveCompletionHandler != NULL)
		self.automaticSaveCompletionHandler(success, error);
}
#endif

@end

@implementation DCTCoreDataStack_ManagedObjectContext

- (BOOL)save:(NSError **)error {
	
	if (![self obtainPermanentIDsForObjects:[[self insertedObjects] allObjects] error:error])
		return NO;
	
	id object = objc_getAssociatedObject(self, @selector(dct_saveWithCompletionHandler:));
	
	if (object) return [super save:error];
	
	__block BOOL success = [super save:error];
	
	if (success) {
		
		NSManagedObjectContext *parent = self.parentContext;
		
		[parent performBlockAndWait:^{
			success = [parent save:error];
		}];
	}
	
	return success;
}

- (void)dct_saveWithCompletionHandler:(void(^)(BOOL success, NSError *error))completion {
	
#ifdef TARGET_OS_IPHONE
	
	UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
	
	void(^iphoneCompletion)(BOOL, NSError *) = ^(BOOL success, NSError *error) {
		
		if (completion != NULL)
			completion(success, error);
		
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
	};
	
	completion = iphoneCompletion;
	
#endif
	
	dispatch_queue_t queue = dispatch_get_current_queue();
	
	NSManagedObjectContext *parent = self.parentContext;
	
	// Put anything in this association to switch on save:
	objc_setAssociatedObject(self, _cmd, [NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[super dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
		
		// Clear the association after the save
		objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
		if (!success) {
			if (completion != NULL)
				completion(success, error);
			
			return;
		}
		
		[parent performBlock:^{
			[parent dct_saveWithCompletionHandler:^(BOOL success, NSError *error) {
				dispatch_async(queue, ^{
					if (completion != NULL)
						completion(success, error);
				});
			}];
		}];
	}];
}

@end
