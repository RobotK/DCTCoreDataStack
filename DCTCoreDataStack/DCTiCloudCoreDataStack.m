//
//  DCTiCloudCoreDataStack.m
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 06.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTiCloudCoreDataStack.h"
#import "_DCTCoreDataStack.h"

#ifdef TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface DCTiCloudCoreDataStack ()
@property (nonatomic, strong) id ubiquityIdentityToken;
@property (nonatomic, readonly) NSURL *ubiquityContainerURL;
@end

@implementation DCTiCloudCoreDataStack {
	NSOperationQueue *_queue;
}

#pragma mark - DCTCoreDataStack

- (void)dealloc {
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter removeObserver:self
							 name:NSUbiquityIdentityDidChangeNotification
						   object:nil];
	[defaultCenter removeObserver:self
							 name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
						   object:nil];

#ifdef TARGET_OS_IPHONE
	[defaultCenter removeObserver:self
							 name:UIApplicationDidBecomeActiveNotification
						   object:[UIApplication sharedApplication]];
#endif
}

- (id)initWithStoreURL:(NSURL *)storeURL
			 storeType:(NSString *)storeType
		  storeOptions:(NSDictionary *)storeOptions
	modelConfiguration:(NSString *)modelConfiguration
			  modelURL:(NSURL *)modelURL {
	
	return [self initWithStoreFilename:[storeURL lastPathComponent]
							 storeType:NSSQLiteStoreType
						  storeOptions:storeOptions
					modelConfiguration:modelConfiguration
							  modelURL:modelURL
		   ubiquityContainerIdentifier:nil];
}

- (id)initWithStoreFilename:(NSString *)filename {
	return [self initWithStoreFilename:filename
							 storeType:NSSQLiteStoreType
						  storeOptions:nil
					modelConfiguration:nil
							  modelURL:nil
		   ubiquityContainerIdentifier:nil];
}

#pragma mark - DCTiCloudCoreDataStack

- (id)initWithStoreFilename:(NSString *)storeFilename
				  storeType:(NSString *)storeType
			   storeOptions:(NSDictionary *)storeOptions
		 modelConfiguration:(NSString *)modelConfiguration
				   modelURL:(NSURL *)modelURL
ubiquityContainerIdentifier:(NSString *)ubiquityContainerIdentifier {

	self = [super initWithStoreURL:nil
						 storeType:storeType
					  storeOptions:storeOptions
				modelConfiguration:modelConfiguration
						  modelURL:modelURL];
	if (!self) return nil;

	_queue = [NSOperationQueue new];
	_queue.maxConcurrentOperationCount = 1;
	_storeFilename = [storeFilename copy];
	_ubiquityContainerIdentifier = [ubiquityContainerIdentifier copy];
	_ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];

	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self
					  selector:@selector(_ubiquityIdentityDidChangeNotification:)
						  name:NSUbiquityIdentityDidChangeNotification
						object:nil];
	[defaultCenter addObserver:self
					  selector:@selector(_persistentStoreDidImportUbiquitousContentChangesNotification:)
						  name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
						object:nil];
	
#ifdef TARGET_OS_IPHONE
	[defaultCenter addObserver:self
					  selector:@selector(_applicationDidBecomeActiveNotification:)
						  name:UIApplicationDidBecomeActiveNotification
						object:[UIApplication sharedApplication]];
#endif

	return self;
}

- (void)setUbiquityIdentityToken:(id)ubiquityIdentityToken {
	if (_ubiquityIdentityToken == nil && ubiquityIdentityToken == nil) return;
	if ([_ubiquityIdentityToken isEqual:ubiquityIdentityToken]) return;
	_ubiquityIdentityToken = ubiquityIdentityToken;
	[self _removePersistentStore];
	[self _loadPersistentStore];
}

- (BOOL)isiCloudAvailable {
	return (self.ubiquityIdentityToken != nil);
}

#pragma mark - Internal

- (void)_removePersistentStore {
	[_queue addOperationWithBlock:^{
		NSPersistentStore *persistentStore = [self.persistentStoreCoordinator persistentStoreForURL:self.storeURL];
		if (persistentStore) [self.persistentStoreCoordinator removePersistentStore:persistentStore error:NULL];
	}];
}

- (void)_loadPersistentStore {
	[_queue addOperationWithBlock:^{
		[super _loadPersistentStore];
		if (self.persistentStoreDidChangeHandler == NULL) return;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.persistentStoreDidChangeHandler();
		});
	}];
}

- (void)_persistentStoreDidImportUbiquitousContentChangesNotification:(NSNotification *)notification {
	if (![notification.object isEqual:self.persistentStoreCoordinator]) return;
	[self.managedObjectContext performBlock:^{
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (NSURL *)ubiquityContainerURL {
	return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:self.ubiquityContainerIdentifier];
}

- (NSURL *)storeURL {

	if (self.ubiquityContainerURL) {
		NSString *storeFilename = [NSString stringWithFormat:@"%@.nosync", self.storeFilename];
		return [self.ubiquityContainerURL URLByAppendingPathComponent:storeFilename];
	}

	return [[[self class] _applicationDocumentsDirectory] URLByAppendingPathComponent:self.storeFilename];
}

- (NSDictionary *)storeOptions {
	NSMutableDictionary *storeOptions = [[super storeOptions] mutableCopy];
	if (!storeOptions) storeOptions = [NSMutableDictionary new];
	[storeOptions setObject:self.storeFilename forKey:NSPersistentStoreUbiquitousContentNameKey];
	NSURL *URL = [self.ubiquityContainerURL URLByAppendingPathComponent:self.storeFilename];
	[storeOptions setObject:URL forKey:NSPersistentStoreUbiquitousContentURLKey];
	return [storeOptions copy];
}

- (void)_ubiquityIdentityDidChangeNotification:(NSNotification *)notification {
	self.ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
}

- (void)_applicationDidBecomeActiveNotification:(NSNotification *)notification {
	self.ubiquityIdentityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
}

@end
