//
//  LogisticsTableViewController.m
//  LogScan
//
//  Created by Paul Collins on 11/29/20.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "LogisticsTableViewController.h"

#import "ItemStatusTableViewCell.h"

@interface LogisticsTableViewController ()

@end

@implementation LogisticsTableViewController

- (UseType)useType {
	return kInventory;
}

- (void)addAction:(id)sender
{
	[self performSegueWithIdentifier: @"showScanner" sender: self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)configureCell:(UITableViewCell *)acell atIndexPath:(NSIndexPath *)indexPath
{
	NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
	ItemStatusTableViewCell *cell = (ItemStatusTableViewCell *)acell;
	
	NSString *text = [NSString stringWithFormat:@"%@, %@", [[object valueForKey:@"surname"] description], [[object valueForKey:@"givenName"] description]];
	cell.personLabel.text = text;

	cell.itemNumberLabel.text = [[object valueForKey:@"itemNumber"] stringValue];

	// Unlike the person's names, the product name only exists in the product.
	NSString *productName = [object valueForKeyPath:@"product.title"];
	cell.itemNameLabel.text =  productName ? productName :[NSString stringWithFormat:@"Item ID %@", [object valueForKey:@"itemTypeID"]];
	
	BOOL isOut = [[object valueForKey:@"isOut"] boolValue];
	cell.itemStatusImage.image = [UIImage imageNamed:( isOut ? @"out" : @"back")];
}


@end
