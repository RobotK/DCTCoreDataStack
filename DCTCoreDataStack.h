/*
 DCTCoreDataStack.h
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


// DCTCoreDataStack is intended for non-document based apps, and provides the following features:
//
// 1) An encapsulation of the complete Core Data stack of NSManagedObjectContext, NSPersistentStoreCoordinator, NSPersistentStore, and NSManagedObjectModel
//
// 2) On new enough OS's that support it, writing to disk is performed on a background thread, by using a parent context. Saving the main context automatically triggers saving the parent context asynchronously
//
// 3) -[NSManagedObjectContext dct_saveWithCompletionHandler:] method can be used to be notified when saving to disk finishes, asynchronously if possible
//
// 4) On iOS, the app entering the background automatically triggers a save
//
// 5) On iOS, when saving on a background thread, the stack protects against termination/suspension by declaring the save as a background task


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#if !defined dct_weak && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0
#define dct_weak weak
#define __dct_weak __weak
#define dct_nil(x)
#elif !defined dct_weak && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_3
#define dct_weak unsafe_unretained
#define __dct_weak __unsafe_unretained
#define dct_nil(x) x = nil
#endif

@interface DCTCoreDataStack : NSObject

// Convenience that assumes XML store, nil config, no options. The model is made up by merging all in the app's main bundle
// Generally the best method to use when getting started
- (id)initWithStoreFilename:(NSString *)filename;

// Store is assumed to be in the app's documents folder
// This method is helpful for when your app has previously been using -initWithStoreFilename: but now needs to migrate an existing store. To do so, specify the name of the *new* model; set the options values corresponding to both the NSMigratePersistentStoresAutomaticallyOption and the NSInferMappingModelAutomaticallyOption keys to YES. For more details see Apple's Core Data versioning and migration guide.
- (id)initWithStoreFilename:(NSString *)storeFilename
				  storeType:(NSString *)storeType
               storeOptions:(NSDictionary *)storeOptions
		 modelConfiguration:(NSString *)modelConfiguration 
                  modelName:(NSString *)modelName;

// Designated initializer
- (id)initWithStoreURL:(NSURL *)storeURL
			 storeType:(NSString *)storeType
		  storeOptions:(NSDictionary *)storeOptions
	modelConfiguration:(NSString *)modelConfiguration
			 modelName:(NSString *)modelName;

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, copy, readonly) NSURL *storeURL;
@property (nonatomic, copy, readonly) NSString *storeType;
@property (nonatomic, copy, readonly) NSDictionary *storeOptions;

@property (nonatomic, copy, readonly) NSString *modelName;
@property (nonatomic, copy, readonly) NSString *modelConfiguration;

@end
