//
//  DCTiCloudCoreDataStack.m
//  DCTCoreDataStack
//
//  Created by Daniel Tull on 06.08.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "DCTiCloudCoreDataStack.h"

@interface DCTiCloudCoreDataStack ()
@property (nonatomic, strong) id currentUbiquityToken;
@end

@implementation DCTiCloudCoreDataStack {
	__strong DCTCoreDataStack *_coreDataStack;
	
	__strong NSURL *_storeURL;
	__strong NSString *_storeType;
	__strong NSDictionary *_storeOptions;
	__strong NSString *_modelConfiguration;
	__strong NSURL *_modelURL;
}

#pragma mark - DCTCoreDataStack

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSUbiquityIdentityDidChangeNotification
												  object:nil];
}

- (id)initWithStoreURL:(NSURL *)storeURL
			 storeType:(NSString *)storeType
		  storeOptions:(NSDictionary *)storeOptions
	modelConfiguration:(NSString *)modelConfiguration
			  modelURL:(NSURL *)modelURL {
	
	self = [self init];
	if (!self) return nil;
	
	NSDictionary *iCloudStoreOptions = @{NSPersistentStoreUbiquitousContentNameKey : [storeURL lastPathComponent],
	NSPersistentStoreUbiquitousContentURLKey : [[self class] _ubiquityURL]};
	
	NSMutableDictionary *options = [NSMutableDictionary new];
	if ([storeOptions count] > 0) [options setValuesForKeysWithDictionary:storeOptions];
	[options setValuesForKeysWithDictionary:iCloudStoreOptions];
	
	_storeURL = [storeURL copy];
	_storeType = [storeType copy];
	_storeOptions = [options copy];
	_modelURL = [modelURL copy];
	_modelConfiguration = [modelConfiguration copy];
	
	[self _loadStack];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_ubiquityIdentityDidChangeNotification:)
                                                 name:NSUbiquityIdentityDidChangeNotification
                                               object:nil];
	
	return self;
}

#pragma mark - DCTiCloudCoreDataStack

+ (void)setUbiquityContainerIdentifier:(NSString *)string {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
	});
}

- (void)setCurrentUbiquityToken:(id)currentUbiquityToken {
	_currentUbiquityToken = currentUbiquityToken;
	[self _loadStack];
}

- (BOOL)isiCloudAvailable {
	return (self.currentUbiquityToken != nil);
}

#pragma mark - Internal

- (void)_loadStack {

	_coreDataStack = [super initWithStoreURL:_storeURL
								   storeType:_storeType
								storeOptions:_storeOptions
						  modelConfiguration:_modelConfiguration
									modelURL:_modelURL];
	
	if (self.iCloudAccountDidChangeHandler) self.iCloudAccountDidChangeHandler();
}

- (void)_ubiquityIdentityDidChangeNotification:(NSNotification *)notification {
	self.currentUbiquityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
}

+ (NSURL *)_ubiquityURL {
    return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
}



#pragma mark - DCTCoreDataStack getters and setters

- (NSManagedObjectContext *)managedObjectContext {
	return _coreDataStack.managedObjectContext;
}

- (BOOL (^)(NSError *))didResolvePersistentStoreErrorHandler {
	return _coreDataStack.didResolvePersistentStoreErrorHandler;
}

- (void)setDidResolvePersistentStoreErrorHandler:(BOOL (^)(NSError *))didResolvePersistentStoreErrorHandler {
	_coreDataStack.didResolvePersistentStoreErrorHandler = didResolvePersistentStoreErrorHandler;
}

- (void (^)(BOOL, NSError *))automaticSaveCompletionHandler {
	return _coreDataStack.automaticSaveCompletionHandler;
}

- (void)setAutomaticSaveCompletionHandler:(void (^)(BOOL, NSError *))automaticSaveCompletionHandler {
	_coreDataStack.automaticSaveCompletionHandler = automaticSaveCompletionHandler;
}


@end
