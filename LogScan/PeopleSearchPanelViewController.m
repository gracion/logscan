//
//  PeopleSearchPanelViewController.m
//  LogScan
//
//  Created by Paul Collins on 1/3/26.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "PeopleSearchPanelViewController.h"
#import "Person+CoreDataProperties.h"

@interface PeopleSearchPanelViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *tapToSignLabel;

@property (nonatomic, copy) NSString *currentQuery;
@property (nonatomic, strong) NSArray<Person *> *people;

@end

@implementation PeopleSearchPanelViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.currentQuery = @"";
	self.people = @[];

	self.searchBar.delegate = self;
	self.searchBar.placeholder = @"Search name or CERT ID";
	self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;

	self.tableView.dataSource = self;
	self.tableView.delegate = self;

	// Register a basic cell - no prototype in storyboard for this view
	// TODO: Consider UIListContentConfiguration, especially if old APIs removed
	[self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"PersonCell"];

	[self fetchPeopleForQuery:self.currentQuery];
}

#pragma mark - Fetch

// query has been trimmed and validated
- (void)fetchPeopleForQuery:(NSString *)query
{
	NSAssert(self.managedObjectContext != nil, @"managedObjectContext missing.");

	NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Person"];

	// Case/diacritic-insensitive substring match against either field
	req.predicate = [NSPredicate predicateWithFormat:
					 @"(givenName CONTAINS[cd] %@) OR (surname CONTAINS[cd] %@)",
					 query, query];

	NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:@"surname"
														 ascending:YES
														  selector:@selector(localizedCaseInsensitiveCompare:)];
	NSSortDescriptor *sd2 = [NSSortDescriptor sortDescriptorWithKey:@"givenName"
														 ascending:YES
														  selector:@selector(localizedCaseInsensitiveCompare:)];
	req.sortDescriptors = @[sd1, sd2];
	req.fetchBatchSize = 50;

	NSError *err = nil;
	NSArray<Person *> *results = [self.managedObjectContext executeFetchRequest:req error:&err];
	if (!results)
	{
		NSLog(@"People fetch failed: %@", err);
		results = @[];
	}

	self.people = results;
	self.tapToSignLabel.hidden = results.count == 0;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.tableView reloadData];
	});
}


- (void)fetchPeopleByID:(NSInteger)personID
{
	NSAssert(self.managedObjectContext != nil, @"managedObjectContext missing.");
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];

	NSNumber *personIDNum = @(personID);
	request.predicate = [NSPredicate predicateWithFormat:@"personID == %@", personIDNum];
	
	request.fetchLimit = 1;
	NSError *error = nil;
	NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];

	if (results == nil) {
		NSLog(@"Error fetching Person by personID %ld: %@", (long)personID, error);
		self.people = @[];
		return;
	}
	
	self.people = results;
	self.tapToSignLabel.hidden = results.count == 0;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.tableView reloadData];
	});
}


#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	NSInteger minLength = 3;
	NSString *trim = [searchText stringByTrimmingCharactersInSet:
						 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	NSInteger numQuery = [trim integerValue];
	if (numQuery > 1)
	{
		[self fetchPeopleByID:numQuery];
		return;
	}
	
	if ([trim isEqualToString:self.currentQuery] || trim.length < minLength)
	{
		return;
	}
	self.currentQuery = searchText;
	[self fetchPeopleForQuery:self.currentQuery];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	searchBar.text = @"";
	self.people = @[];
	[self.tableView reloadData];
}


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	searchBar.showsCancelButton = YES;
}


- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	searchBar.showsCancelButton = NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.people.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PersonCell" forIndexPath:indexPath];

	Person *person = self.people[indexPath.row];
	NSString *given = person.givenName ?: @"(blank)";
	NSString *surname = person.surname ?: @"(blank)";
	
	cell.textLabel.text = [NSString stringWithFormat:@"%@, %@", surname, given];
	return cell;
}


#pragma mark - UITableViewDelegate (optional)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	Person *person = self.people[indexPath.row];
	
	// Pass id string as if scanned for normal behavior
	NSString *idStr = [NSString stringWithFormat:@"%@", person.personID];
	if ([idStr isEqualToString:self.scanViewController.lastScanData])
	{
		// ignore extra taps
		return;
	}
	self.scanViewController.resultText.text = idStr;
	[self.scanViewController scanIn:idStr];
	
	// this has to be after scanIn is called
	self.scanViewController.lastScanData = idStr;
	self.scanViewController.idEntryField.text = @"";
}

@end
