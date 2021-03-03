//
//  SigninTableViewController.m
//  LogScan
//
//  Created by Paul Collins on 11/29/20.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "SigninTableViewController.h"

#import "SignInTableViewCell.h"


@interface SigninTableViewController ()

@end

@implementation SigninTableViewController

- (UseType)useType {
	return kSignIn;
}

- (void)addAction:(id)sender
{
	[self performSegueWithIdentifier: @"showSigninScanner" sender: self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.timeFormatter = [[NSDateFormatter alloc] init];
    [self.timeFormatter setDateFormat:@"HH:mm"];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    if ([[[NSLocale currentLocale] localeIdentifier] isEqualToString:@"en_US"])
		[self.dateFormatter setDateFormat:@"M/d"];
	else
		[self.dateFormatter setDateFormat:@"d-M"];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)configureCell:(UITableViewCell *)acell atIndexPath:(NSIndexPath *)indexPath
{
	NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
	SignInTableViewCell *cell = (SignInTableViewCell *)acell;
		
	NSString *text = [NSString stringWithFormat:@"%@, %@", [[object valueForKey:@"surname"] description], [[object valueForKey:@"givenName"] description]];
	cell.personLabel.text = text;
	
	NSDate *dateTime = [object valueForKey:@"outTime"];
	text = [self.timeFormatter stringFromDate:dateTime];
	cell.inLabel.text = text;
	
	BOOL isSignedIn = [[object valueForKey:@"isOut"] boolValue];
	if (isSignedIn)
	{
		cell.outLabel.text = @"";
		text = [self.dateFormatter stringFromDate:dateTime];
		cell.dateLabel.text = text;
	}
	else
	{
		dateTime = [object valueForKey:@"inTime"];
		text = [self.timeFormatter stringFromDate:dateTime];
		cell.outLabel.text = text;
		text = [self.dateFormatter stringFromDate:dateTime];
		cell.dateLabel.text = text;
	}

//	// Unlike the person's names, the product name only exists in the product.
//	NSString *productName = [object valueForKeyPath:@"product.title"];
//	cell.itemNameLabel.text =  productName ? productName :[NSString stringWithFormat:@"Item ID %@", [object valueForKey:@"itemTypeID"]];
	
	cell.statusImage.image = [UIImage imageNamed:( isSignedIn ? @"signedIn" : @"signedOut")];
	
}

@end
