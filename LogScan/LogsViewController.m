//
//  LogsViewController.m
//  LogScan

//	View showing table of persons linked to logistic uses or signins, linked to detail views
//	with abilities to scan and edit
//
//  Created by Paul A Collins on 4/23/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "LogsViewController.h"

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "SendViewController.h"
#import "SettingsViewController.h"
#import "ItemStatusTableViewCell.h"
#import "NSString+Utilities.h"
#import "Person+CoreDataProperties.h"
#import "Product+CoreDataProperties.h"
#import "ItemUse+CoreDataProperties.h"
#import "SignInTableViewCell.h"

NSString * const kPPFName = @"LogScanPersonsAndProducts";
NSString * const kItemFName = @"LogScanLog";

@interface LogsViewController ()

@end

@implementation LogsViewController

- (void)awakeFromNib {
	[super awakeFromNib];
	// This isn't once per launch but small potatoes
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.navigationItem.leftBarButtonItem = self.editButtonItem;

	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction:)];
	self.navigationItem.rightBarButtonItem = addButton;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


// TODO: put something like this in the other classes that use UIAlertView (deprecated).

- (void)errorAlertOnError:(NSError *)err
{
	UIAlertController *ctrlr = [UIAlertController alertControllerWithTitle:@"Internal Error" message:[err localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
	[ctrlr addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:ctrlr animated:YES completion:nil];
}


- (NSString *)calc
{
	return @"";
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([[segue identifier] isEqualToString:@"showDetail"]) {
	    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	    [[segue destinationViewController] setDetailItem:object];
	}
	else if ([[segue destinationViewController] isKindOfClass:[ScanViewController class]])
	{
		[(ScanViewController *)[segue destinationViewController] setMyMaster:self];
	}
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return NO if you do not want the specified item to be editable.
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
	    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
	    [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
		[[AppDelegate myApp] setNeedsSave];
	}
}

- (void)configureCell:(UITableViewCell *)acell atIndexPath:(NSIndexPath *)indexPath
{	// must override
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ItemUse" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"outTime" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"useType = %@", @(self.useType)];
	[fetchRequest setPredicate:predicate];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName: self.useType == kSignIn ? @"SignIn" : @"Logistics"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	if (self.tableView.window)
	{
		[self.tableView beginUpdates];
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}


// Future: The current implementation of this controller could be vulnerable to display issues.
// Inserting an ItemUse with a one-to-one relationship that nullified the existing relationship
//  of an other ItemUse caused the old object's call in the table to draw with the new object's info
// Fortunately, it was supposed to be a one-to-many relationship, and changing that avoided the problem.
// But it doesn't give me great confidence that this implementation is as robust as it should be.
// I could see the problem by setting a breakpoint on this method and seeing it called twice. --PaulC 12/27/15
// Ok, hasn't really been a problem in five years of use by us --PaulC 12/24/20

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
			if (tableView.window)
			{
				[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			}
			else
			{
				// Clear all entries happens when tableView is offscreen and deleteRowsAtIndexPaths would fail
				// // (UITableViewAlertForLayoutOutsideViewHierarchy)
				[tableView reloadData];
			}
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */


- (void)acceptScanObject:(ScanViewController *)ctrlr
{
	// This is creation of ItemUse due to an out scan of person and item
	
	NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
	NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
	NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
	
	// If appropriate, configure the new managed object.
	// Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
	[newManagedObject setValue:@(self.useType) forKey:@"useType"];
	
	[newManagedObject setValue:@(ctrlr.personID) forKey:@"personID"];
	[newManagedObject setValue:@(ctrlr.itemTypeID) forKey:@"itemTypeID"];
	[newManagedObject setValue:@(ctrlr.itemNumber) forKey:@"itemNumber"];
	
	[newManagedObject setValue:ctrlr.productObj forKey:@"product"];
	[newManagedObject setValue:ctrlr.personObj forKey:@"person"];

	// Because LogScan was inventory-only at first, for sign-in, YES means "signed-in"
	// A better name might be "isAttached" or "isInUse"
	[newManagedObject setValue:@(YES) forKey:@"isOut"];
	[newManagedObject setValue:[NSDate date] forKey:@"outTime"];
	if ([ctrlr.surname length])
	{
		[newManagedObject setValue:ctrlr.surname forKey:@"surname"];
		[newManagedObject setValue:ctrlr.givenName forKey:@"givenName"];
	}
	else
	{
		NSArray *parts = @[[NSString stringWithFormat:@"%ld", (long)ctrlr.personID], @"ID"];
		[newManagedObject setValue:parts[0] forKey:@"surname"];
		[newManagedObject setValue:parts[1] forKey:@"givenName"];
	}
	
	// Let's save immediately now that we have a complete event
	[[AppDelegate myApp] saveContext];
	
	[self notifySignIn:(ItemUse *)newManagedObject isIn:YES];
}


// TODO: this probably belongs in ScanViewController. And why are we doing an ItemUse search
// If we knew the item was out?

- (NSManagedObject *)acceptScanIn:(ScanViewController *)ctrlr error:(NSError **)anError
{
	NSManagedObjectContext *moc = [self.fetchedResultsController managedObjectContext];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ItemUse" inManagedObjectContext:moc];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	// Find the item use - note that ctrlr may have a different person data because of pending re-checkout
	// We always checkin one instance of the item, whatever is found first
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(itemNumber = %@) AND (itemTypeID = %@) AND (isOut = YES) AND (useType = %@)", @(ctrlr.itemNumber), @(ctrlr.itemTypeID), @(self.useType)];
	[request setPredicate:pred];
	
	NSArray *array = [moc executeFetchRequest:request error:anError];
	if (!array) {
		NSLog(@"error fetching for acceptScanIn %@", [*anError localizedDescription]);
		return nil;
	}
	if ([array count] > 0)
	{
		NSManagedObject *obj = array[0];
		[obj setValue:@(NO) forKey:@"isOut"];
		[obj setValue:[NSDate date] forKey:@"inTime"];
		// Must save now to avoid stale index in controller:didChangeObject:
		[[AppDelegate myApp] saveContext];
		
		[self notifySignIn:(ItemUse *)obj isIn:NO];
		
		return obj;
	}
	return nil;
}


#pragma mark - Mattermost notification

// This posts "Signed in John Smith" to a channel

- (void)notifySignIn:(ItemUse *)itemUse isIn:(BOOL)isIn
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"mattermostNotifyOn"])
	{
		return;
	}

	CFTypeRef result;
	OSStatus ok = SecItemCopyMatching((__bridge CFDictionaryRef)[SettingsViewController mattermostSearchQuery],
									  &result);
	
	if (ok == errSecSuccess)
	{
		NSString *channel =(__bridge NSString *)CFDictionaryGetValue( result, kSecAttrAccount );
		NSString *server = (__bridge NSString *)CFDictionaryGetValue( result, kSecAttrService );
		NSData *tokenData = (__bridge NSData *)CFDictionaryGetValue( result, kSecValueData );
		NSString *token = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
		CFRelease( result );
		
		NSString *msg = nil;
		if ([itemUse.itemTypeID intValue] == 0)
		{
			msg = [NSString stringWithFormat:@"Signed %@ %@ %@", isIn ? @"in" : @"out",
						 itemUse.givenName, itemUse.surname];
		}
		else
		{
			msg = [NSString stringWithFormat:@"Checked %@ %@ %@ %@ %@ %@",
					isIn ? @"out" : @"in",
					itemUse.product.title,
					itemUse.itemNumber,
					isIn ? @"to" : @"from",
					itemUse.givenName, itemUse.surname];
		}
		// To get the channel_id, you're supposed to use the Mattermost command line.
		// https://docs.mattermost.com/administration/command-line-tools.html
		// But I gave up and got it directly by browsing the SQL database on the server.
		NSDictionary *jsonDict = @{@"channel_id":channel, @"message" : msg };
		
		NSData *json = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
		NSAssert(json, @"json not encoded");
		
		NSString *proto = [server rangeOfString:@"http"].location == 0 ? @"" : @"https://";
		NSString *urlstr = [NSString stringWithFormat:@"%@%@/api/v4/posts", proto, server];
		NSString *authstr = [NSString stringWithFormat:@"Bearer %@", token];
		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlstr]];
		req.HTTPMethod = @"POST";
		req.HTTPBody = json;
		[req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[req setValue:authstr forHTTPHeaderField:@"Authorization"];
		
		NSURLSession *sess = [NSURLSession sharedSession];
		NSURLSessionDataTask *task = [sess dataTaskWithRequest:req completionHandler:
									  ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
			long rtnCode = [(NSHTTPURLResponse *)response statusCode];
			if (rtnCode != 201)
			{
				NSLog(@"Unexpected %ld response to Mattermost post: %@", rtnCode,
					  [(NSHTTPURLResponse *)response allHeaderFields]);
			}
		}];
		[task resume];
	}
	else
	{
		NSLog(@"Error getting Mattermost credentials from Keychain: %d", (int)ok);
	}
}


@end
