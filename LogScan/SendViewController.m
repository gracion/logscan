//
//  UtilityViewController.m
//  LogScan
//
//  Created by Paul A Collins on 10/25/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "SendViewController.h"

#import "AppDelegate.h"
#import "Person+CoreDataProperties.h"
#import "Product+CoreDataProperties.h"
#import "ItemUse+CoreDataProperties.h"

extern NSString * const kCSVFileDateFormat;

@interface SendViewController ()

@end

@implementation SendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Export the person and product tables as a csv file
- (IBAction)exportPersonProductData:(id)sender
{
	[self export:kPersonAndData inMode:[sender tag] == 1 ? kFile : kText];
}

// Clear all items from log (both?)
- (IBAction)clearLogEntries:(id)sender
{
	[self askUser:@"Are you sure you want to clear all log entries?" actionTitle:@"Clear All" cancelTitle:@"Cancel" destructive:YES onViewController:self];
}


#pragma mark - Exporting

- (IBAction)exportAction:(id)sender
{
	DataType type = self.inventorySwitch.on ? kItemUses : 0;
	if (self.signInSwitch.on)
	{
		type += kSignIns;
	}
	[self export:type inMode:kFile];
}

- (void)export:(DataType)dt inMode:(ExportType)mode
{
	//Create an activity view controller with the url container as its activity item.
	
	NSError *err = nil;
	// We'll just create the csv and deliver it
	[self fixNamesInItemUses];
	NSMutableArray *csvs = [NSMutableArray arrayWithCapacity:2];
	NSMutableArray<NSNumber *> *types = [NSMutableArray arrayWithCapacity:2];
	
	if (dt & kPersonAndData)
	{
		[csvs addObject:[self csvFromPersonsAndProducts]];
		[types addObject:@(kPersonAndData)];
	}
	if (dt & kSignIns)
	{
		NSString *csv = [self csvFromItemUses:kSignIn];
		if (csv.length > 0)
		{
			[csvs addObject:csv];
			[types addObject:@(kSignIns)];
		}
	}
	if (dt & kItemUses)
	{
		NSString *csv = [self csvFromItemUses:kInventory];
		if (csv.length > 0)
		{
			[csvs addObject:csv];
			[types addObject:@(kItemUses)];
		}
	}
	NSMutableArray *activityItems = [NSMutableArray arrayWithCapacity:2];

	if (mode != kText)
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *cacheDirs = [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
		if ([cacheDirs count])
		{
			NSURL *cd = cacheDirs[0];
			NSURL *dirPath = [cd URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
			// If the directory does not exist, this method creates it.
			// This method is only available in OS X v10.7 and iOS 5.0 or later.
			NSError*    theError = nil;
			if ([fm createDirectoryAtURL:dirPath withIntermediateDirectories:YES attributes:nil error:&theError])
			{
				// created or exists
				for (NSUInteger i = 0; i < [csvs count]; i++)
				{
					// See enum DataType
					NSString *name = @[@"LogScanPersonsAndProducts.csv", @"Logistics.csv", @"", @"SignIn.csv"][types[i].intValue - 1];
					NSURL *filePath = [dirPath URLByAppendingPathComponent:name];
					NSString *csv = csvs[i];
					if ([csv writeToURL:filePath atomically:NO encoding:NSUTF8StringEncoding error:&err])
					{
						[activityItems addObject:filePath];
					}
					else
					{
						NSLog(@"Error writing csv cache file: %@", [err localizedDescription]);
					}
				}
			}
		}
	}

	if (!activityItems)
		activityItems = csvs;
	
	
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];

	[self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Data Utilities

// Currently, this only handles the answer to the alert for clearLogEntries
// Also this is the only controller
- (void)performOnAnswer:(BOOL)answer onController:(SendViewController *)mvc
{
	if (answer == YES)
	{
		[mvc clearAllLogEntries];
	}
}


- (void)clearAllLogEntries
{
	NSArray *objs = [[AppDelegate myApp] allItemsOfType:kAny];
	for (NSManagedObject *obj in objs)
	{
		[_managedObjectContext deleteObject:obj];
	}
	[[AppDelegate myApp] saveContext];
}


- (NSString *)csvFromItemUses:(UseType)useType;
{
	NSDateFormatter *dateFmtr = [[NSDateFormatter alloc] init];
	[dateFmtr setDateFormat:@"yyyy-MM-dd"];
	NSDateFormatter	*timeFmtr = [[NSDateFormatter alloc] init];
	[timeFmtr setDateFormat:@"HH:mm"];
	
	// get everything, sorted by time out, and put into csv
	NSArray *objs = [[AppDelegate myApp] allItemsOfType:useType];
	
	NSMutableString *str;
	if ( useType == kInventory)
	{
		str = [[NSMutableString alloc] initWithString:@"Date Out,Time Out,Date In,Time In,ItemTypeID,ItemNumber,ItemName,PersonID,Surname,Given Name\n"];
		
		for (NSManagedObject *obj in objs)
		{
			NSDate *inTime = [obj valueForKey:@"inTime"];
			NSNumber *itemID =(NSNumber *)[obj valueForKey:@"itemTypeID"];
			NSString *productName = [obj valueForKeyPath:@"product.title"];
			
			NSString *line = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
							  [dateFmtr stringFromDate:[obj valueForKey:@"outTime"]],
							  [timeFmtr stringFromDate:[obj valueForKey:@"outTime"]],
							  inTime ? [dateFmtr stringFromDate:[obj valueForKey:@"inTime"]] : @"",
							  inTime ? [timeFmtr stringFromDate:[obj valueForKey:@"inTime"]] : @"",
							  [itemID stringValue],
							  [[obj valueForKey:@"itemNumber"] stringValue],
							  productName,
							  [[obj valueForKey:@"personID"]  stringValue],
							  [obj valueForKey:@"surname"],
							  [obj valueForKey:@"givenName"]];
			[str appendString:line];
		}
	}
	else
	{
		// signin
		str = [[NSMutableString alloc] initWithString:@"Date In,Time In,Date Out,Time out,PersonID,Surname,Given Name\n"];
		
		for (NSManagedObject *obj in objs)
		{
			NSDate *inTime = [obj valueForKey:@"inTime"];
			NSString *line = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@\n",
							  // Remember, these are reversed meaning for signins
							  [dateFmtr stringFromDate:[obj valueForKey:@"outTime"]],
							  [timeFmtr stringFromDate:[obj valueForKey:@"outTime"]],
							  inTime ? [dateFmtr stringFromDate:[obj valueForKey:@"inTime"]] : @"",
							  inTime ? [timeFmtr stringFromDate:[obj valueForKey:@"inTime"]] : @"",
							  [[obj valueForKey:@"personID"]  stringValue],
							  [obj valueForKey:@"surname"],
							  [obj valueForKey:@"givenName"]];
			[str appendString:line];
		}
		
	}
	return str;
}


- (BOOL)fixNamesInItemUses
{
	NSInteger fixed = 0;
	NSArray *objs = [[AppDelegate myApp] allItemsOfType:kAny];

	for (ItemUse *use in objs)
	{
		if ([use.givenName isEqualToString:@"ID"])
		{
			// See if we got a better name
			Person *pers = [[AppDelegate myApp] findOrCreatePersonWithID:[use.personID integerValue]];
			if ([pers.surname length] && ![pers.surname isEqualToString:use.surname])
			{
				use.surname = pers.surname;
				fixed++;
			}
			if ([pers.givenName length] && ![pers.givenName isEqualToString:use.givenName])
			{
				use.givenName = pers.givenName;
				fixed++;
			}
		}
	}
	if (fixed > 0)
	{
		NSLog(@"%lu Person names fixed in ItemUses", (long)fixed);
		[[AppDelegate myApp] saveContext];
	}
	return fixed > 0;
}


- (NSArray *)allObjectsOfEntityName:(NSString *)ename sortedBy:(NSArray *)sortKeys
{
	NSError *err = nil;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:ename inManagedObjectContext:_managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	NSMutableArray *sdecs = [NSMutableArray arrayWithCapacity:[sortKeys count]];
	for (NSString *skey in sortKeys) {
		[sdecs addObject:[[NSSortDescriptor alloc] initWithKey:skey ascending:YES]];
	}
	[request setSortDescriptors:sdecs];
	
	NSArray *array = [_managedObjectContext executeFetchRequest:request error:&err];
	if (!array) {
		NSLog(@"error fetching for allObjects %@", [err localizedDescription]);
		return nil;
	}
	return array;
}


- (NSString *)csvFromPersonsAndProducts
{
	NSMutableString *str = [[NSMutableString alloc] initWithString:@"Entity,ID,Modified,Title,Surname,Given Name,Level,Affiliation\n"];
	NSDateFormatter *dateFmtr = [[NSDateFormatter alloc] init];
	[dateFmtr setDateFormat:kCSVFileDateFormat];
	
	NSArray *objs = [self allObjectsOfEntityName:@"Person" sortedBy:@[@"surname", @"givenName"]];
	for (Person *per in objs)
	{
		NSString *line = [NSString stringWithFormat:@"Person,%@,%@,,%@,%@,%@,%@\n",
						  [per personID],
						  [dateFmtr stringFromDate:[per modified]],
						  [per surname] ? [per surname] : [NSString stringWithFormat:@"Person %@", [per personID]],
						  [per givenName] ? [per givenName] : @"",
						  [per level] ? [per level] : @"",
						  [per affiliation] ? [per affiliation] : @""];
		[str appendString:line];
	}
	objs = [self allObjectsOfEntityName:@"Product" sortedBy:@[@"title", @"productID"]];
	for (Product *pro in objs)
	{
		NSString *line = [NSString stringWithFormat:@"Product,%@,%@,%@\n",
						  [pro productID],
						  [dateFmtr stringFromDate:[pro modified]],
						  [pro title] ? [pro title] : @"Untitled"];
		[str appendString:line];
	}
	return str;
}


- (void)errorAlertOnError:(NSError *)err
{
	UIAlertController *ctrlr = [UIAlertController alertControllerWithTitle:@"Internal Error" message:[err localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
	[ctrlr addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:ctrlr animated:YES completion:nil];
}


- (void)askUser:(NSString *)question actionTitle:(NSString *)atitle cancelTitle:(NSString *)ctitle
	destructive:(BOOL)isScary onViewController:(UIViewController *)vc
{
	UIAlertController *ctrlr = [UIAlertController alertControllerWithTitle:question message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[ctrlr addAction:[UIAlertAction actionWithTitle:atitle style:isScary ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self performOnAnswer:YES onController:self];
	}]];
	[ctrlr addAction:[UIAlertAction actionWithTitle:ctitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		[self performOnAnswer:NO onController:self];
	}]];
	[vc presentViewController:ctrlr animated:YES completion:nil];
}


#pragma mark - Navigation
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
