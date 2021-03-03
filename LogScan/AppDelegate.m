//
//  AppDelegate.m
//  LogScan
//
//  Created by Paul A Collins on 4/23/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "FileImporter.h"
#import "LogsViewController.h"
#import "SendViewController.h"

#import "Person+CoreDataProperties.h"
#import "Product+CoreDataProperties.h"

@interface MyPersistentContainer : NSPersistentContainer
@end

@implementation MyPersistentContainer

// While not required by NSPersistentContainer, which defaults to Application Support, LogScan 1
// under the old Core Data system used the Documents directory, so we'll continue to do that.
// This directory can be exposed in iTunes File Sharing () if info.plist flag is set.
//
+ (NSURL *)defaultDirectoryURL {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.gracion.LogScan" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (AppDelegate *)myApp
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions API_AVAILABLE(ios(6.0))
{
	srand((unsigned int)time(NULL));
	return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	// If you have a top-level tab view
	UITabBarController *tabCtrlr = (UITabBarController *)self.window.rootViewController;
	
	// Pass moc to logistics and signin main controllers
	UINavigationController *nav = tabCtrlr.viewControllers[0];
	self.logisticsTableViewController = (LogsViewController *)nav.topViewController;
	_logisticsTableViewController.managedObjectContext = self.managedObjectContext;
	nav = tabCtrlr.viewControllers[1];
	self.signinTableViewController = (LogsViewController *)nav.topViewController;
	_signinTableViewController.managedObjectContext = self.managedObjectContext;
//	nav = tabCtrlr.viewControllers[2];
	self.sendViewController = (SendViewController *)tabCtrlr.viewControllers[2];
	_sendViewController.managedObjectContext = self.managedObjectContext;

	// Send controller doesn't need a moc, it's just controls and prefs
	
	// check for importing file from other app
	NSURL *importURL = launchOptions[UIApplicationLaunchOptionsURLKey];
	
	if (importURL) {
//		NSString *source = launchOptions[UIApplicationLaunchOptionsSourceApplicationKey];
//		id anno = launchOptions[UIApplicationLaunchOptionsAnnotationKey];
		// Apparently an openURL function will be called as long as we return yes here
		NSLog(@"LaunchOptions URL received:%@", importURL);
	}
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	// Saves changes in the application's managed object context before the application terminates.
	[self saveContext];
}

// called by Open In..
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
	NSError *err = nil;
	// We handle csv files associating people with IDs and products with IDs
	if (!self.fileImporter)
		self.fileImporter = [[FileImporter alloc] init];
	
	BOOL ok = [self.fileImporter importURL:url dbController:self.logisticsTableViewController error:&err];
	// Update table which may be displaying placeholders like "Item ID 1"
	[self.logisticsTableViewController.tableView reloadData];
	if (!ok)
	{
		[self errorAlertOnError:err title:[NSString stringWithFormat:@"Can't import %@", [url lastPathComponent]]];
		return NO;
	}
	// Product format: ID, Name
	
	// We do not import exported logs. Possible use case to switch logs, but better to support switching
	// in Core Data or iCloud or something.
	return ok;
}

- (void)errorAlertOnError:(NSError *)err title:(NSString *)title
{
	if (!title)
	{
		title = @"Internal Error";
	}
	UIAlertController *ctrlr = [UIAlertController alertControllerWithTitle:title message:[err localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
	[ctrlr addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[[(UITabBarController *)[self.window rootViewController] selectedViewController] presentViewController:ctrlr animated:YES completion:nil];
}

- (void)deferredWarningAlert:(NSString *)message
{
	[self performSelector:@selector(doDeferredAlert:) withObject:message afterDelay:0.0];
}

- (void)doDeferredAlert:(NSString *)message
{
	NSError *err = [NSError errorWithDomain:@"com.gracion.logscan" code:1 userInfo:@{ NSLocalizedFailureReasonErrorKey: message }];
	[[AppDelegate myApp] errorAlertOnError:err title:@"Warning"];
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSManagedObjectContext *)managedObjectContext
{
	return self.persistentContainer.viewContext;
}

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
# if 0
			// FIRST LAUNCH STARTS WITH DEMO DATA - for making screenshots in simulator
			NSArray *storeInfo = @[@"LogScan.sqlite", @"LogScan.sqlite-shm", @"LogScan.sqlite-wal"];
			NSURL *checkURL = [[MyPersistentContainer defaultDirectoryURL] URLByAppendingPathComponent:storeInfo[0]];
			if (![[NSFileManager defaultManager] fileExistsAtPath:[checkURL path]]) {
				for (NSString *storeName in storeInfo) {
					NSURL *storeURL = [[MyPersistentContainer defaultDirectoryURL] URLByAppendingPathComponent:storeName];
					NSURL *preloadURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"DemoData" ofType:[storeName pathExtension]]];
					NSError* err = nil;
					if (![[NSFileManager defaultManager] copyItemAtURL:preloadURL toURL:storeURL error:&err]) {
						NSLog(@"Preloaded database file copy failed: %@", [err localizedDescription]);
					}
				}
			}
#endif
			_persistentContainer = [[MyPersistentContainer alloc] initWithName:@"LogScan"];
			[_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
					[self errorAlertOnError:error title:@"Core Data setup error. May need to delete and reinstall app."];
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
#ifdef DEBUG
                    abort();
#endif
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

// saving context when needed by OS or when app code has changes

- (void)saveContext {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveContext) object:nil];
	NSManagedObjectContext *context = self.persistentContainer.viewContext;
	NSError *error = nil;
	if ([context hasChanges] && ![context save:&error]) {
		[self errorAlertOnError:error title:@"Core Data save error"];
		NSLog(@"Unresolved error %@, %@", error, error.userInfo);
#ifdef DEBUG
		abort();
#endif
	}
}


- (void)setNeedsSave {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveContext) object:nil];
	[self performSelector:@selector(saveContext) withObject:nil afterDelay:0.3];
}


#pragma mark - Core Data Utilities

- (Person *)findOrCreatePersonWithID:(NSInteger)personID
{
	NSError *err = nil;
	Person *obj = nil;
	
	// find
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	NSNumber *pid = @(personID);
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"personID = %@", pid];
	[request setPredicate:predicate];
	NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&err];
	if ([array count] > 0)
		obj = array[0];
	else if (err)
		NSLog(@"Person fetch error: %@", [err localizedDescription]);
	
	// create
	if (!obj) {
		obj = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
		obj.personID = @(personID);
		obj.modified = [NSDate date];
		[self setNeedsSave];
	}
	
	return obj; // TODO
}

- (Product *)findOrCreateProductWithID:(NSInteger)productID
{
	NSError *err = nil;
	Product *obj = nil;
	
	// find
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	NSNumber *pid = @(productID);
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"productID = %@", pid];
	[request setPredicate:predicate];
	NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&err];
	if ([array count] > 0)
		obj = array[0];
	else if (err)
		NSLog(@"Product fetch error: %@", [err localizedDescription]);
	
	// create
	if (!obj) {
		obj = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
		obj.productID = @(productID);
		obj.modified = [NSDate date];
		[self setNeedsSave];
	}
	
	return obj;
}


- (Product *)locationWithID:(NSInteger)locationID
{
	NSError *err = nil;
	Product *obj = nil;
	
	// find
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	NSNumber *pid = @(locationID);
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"productID = %@ AND isLocation = YES", pid];
	[request setPredicate:predicate];
	NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&err];
	if ([array count] > 0)
		obj = array[0];
	else if (err)
		NSLog(@"Product fetch error: %@", [err localizedDescription]);
	
	// create
	if (!obj) {
		obj = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
		obj.productID = @(locationID);
		obj.modified = [NSDate date];
		obj.isLocation = @(YES);
		// TODO, current location
		obj.latitude = @(0.);
		obj.longitude = @(0.);
		obj.title = @"Unknown location";
		
		[self setNeedsSave];
	}
	
	return obj;
}


static const double s_degreePrecisionLon = 100. / 82642.;
static const double s_degreePrecisionLat = 100. / 111073.;

- (Product *)locationWithCoordinates:(CLLocation*)loc
{
	NSError *err = nil;
	Product *obj = nil;
	
	// find
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	NSNumber *maxLon = @(loc.coordinate.longitude + s_degreePrecisionLon);
	NSNumber *minLon = @(loc.coordinate.longitude - s_degreePrecisionLon);
	NSNumber *maxLat = @(loc.coordinate.latitude + s_degreePrecisionLat);
	NSNumber *minLat = @(loc.coordinate.latitude - s_degreePrecisionLat);
		
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isLocation = YES AND longitude BETWEEN %@ AND latitude BETWEEN %@", @[minLon, maxLon], @[minLat, maxLat]];
	[request setPredicate:predicate];
	NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&err];
	if ([array count] > 0)
		obj = array[0];
	else if (err)
		NSLog(@"Product fetch error: %@", [err localizedDescription]);
	
	// create
	if (!obj) {
		obj = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
		
		// Random negative product ID, so 1:2B chance of collision
		obj.productID = @(- rand());
		obj.modified = [NSDate date];
		obj.isLocation = @(YES);
		obj.title = [NSString stringWithFormat:@"%.3lf %.3lf", loc.coordinate.latitude, loc.coordinate.longitude];
		// TODO, current location
		obj.latitude = @(loc.coordinate.latitude);
		obj.longitude = @(loc.coordinate.longitude);
		
		[self setNeedsSave];
	}
	
	return obj;
}


- (NSArray *)allItemsOfType:(UseType)useType
{
	NSError *err = nil;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ItemUse"
												inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];

	NSSortDescriptor *sd1 = [[NSSortDescriptor alloc]
										initWithKey:@"outTime" ascending:YES];
	[request setSortDescriptors:@[sd1]];

	if (useType != kAny)
	{
		NSNumber *ut = @(useType);
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"useType = %@", ut];
		[request setPredicate:predicate];
	}
	
	NSArray *array = [self.managedObjectContext executeFetchRequest:request error:&err];
	if (!array) {
		NSLog(@"error fetching for allItems %@", [err localizedDescription]);
		return nil;
	}
	return array;
}



@end
