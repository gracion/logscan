//
//  AppDelegate.h
//  LogScan
//
//  Created by Paul A Collins on 4/23/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@class FileImporter;
@class LogsViewController;
@class Person;
@class Product;
@class SendViewController;

typedef enum : NSUInteger {
	kAny = 0,
	kInventory = 1,
	kSignIn = 2
} UseType;	// ItemUse.useType


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;
// keep container's MOC for convenience
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) FileImporter *fileImporter;
@property (weak, nonatomic) LogsViewController *logisticsTableViewController;
@property (weak, nonatomic) SendViewController *sendViewController;

+ (AppDelegate *)myApp;

- (void)setNeedsSave;
- (void)saveContext;

- (void)deferredWarningAlert:(NSString *)message;

// NonUI Data functionality. TODO: spin off into separate utility class


- (Person *)findOrCreatePersonWithID:(NSInteger)personID;
- (Product *)findOrCreateProductWithID:(NSInteger)productID;
- (Product *)locationWithID:(NSInteger)locationID;
- (Product *)locationWithCoordinates:(CLLocation*)loc;

- (NSArray *)allItemsOfType:(UseType)useType;

@end

