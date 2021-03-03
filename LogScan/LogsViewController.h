//
//  LogsViewController.h
//  LogScan
//
//  Created by Paul A Collins on 4/23/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "AppDelegate.h"
#import "ScanViewController.h"
#import "ItemUse+CoreDataProperties.h"

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


// Future
typedef enum: NSInteger {
	kUnknownID = NSIntegerMin + 1
} LogScanConst;

extern NSString * const kPPFName;
extern NSString * const kItemFName;

@interface LogsViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (readonly) UseType useType;	// subclassed

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)acceptScanObject:(ScanViewController *)ctrlr;

// mark item in, and return item object so you can display person
- (NSManagedObject *)acceptScanIn:(ScanViewController *)ctrlr error:(NSError **)anError;

// Mattermost notification for sign out
- (void)notifySignIn:(ItemUse *)itemUse isIn:(BOOL)isIn;
@end

