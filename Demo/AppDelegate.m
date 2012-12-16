//
//  AppDelegate.m
//  Demo
//
//  Created by Daniel Tull on 24.07.2012.
//  Copyright (c) 2012 Daniel Tull. All rights reserved.
//

#import "AppDelegate.h"
#import <DCTCoreDataStack/DCTCoreDataStack.h>
#import "Event.h"
#import "ViewController.h"

@implementation AppDelegate {
	DCTiCloudCoreDataStack *coreDataStack;
}

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	coreDataStack = [[DCTiCloudCoreDataStack alloc] initWithStoreFilename:@"DCTCoreDataStack"];
	NSManagedObjectContext *managedObjectContext = coreDataStack.managedObjectContext;
	
	ViewController *viewController = [ViewController new];
	viewController.managedObjectContext = managedObjectContext;
	coreDataStack.persistentStoreDidChangeHandler = ^{
		viewController.managedObjectContext = managedObjectContext;
	};

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
