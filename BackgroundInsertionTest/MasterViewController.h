//
//  MasterViewController.h
//  BackgroundInsertionTest
//
//  Created by Daniel Tull on 15.12.2011.
//  Copyright (c) 2011 Daniel Tull Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext, *backgroundProcessingContext;
@end
