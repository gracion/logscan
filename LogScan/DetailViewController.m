//
//  DetailViewController.m
//  LogScan
//
//  Created by Paul A Collins on 4/23/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "DetailViewController.h"
#import "LogsViewController.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
	if (_detailItem != newDetailItem) {
	    _detailItem = newDetailItem;
	        
	    // Update the view.
	    [self configureView];
	}
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Create a date formatter to be used to format the "date" items.
	self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateFormat:@"HH:mm yyyy-MM-dd"];
	
	// Get the master view controller
	NSArray *ctrlrs = [(UINavigationController *)self.parentViewController viewControllers];
	if ([ctrlrs count])
		self.master = ctrlrs[0];
	
	[self configureView];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


- (void)configureView {
	// Update the user interface for the detail item.

	if (self.detailItem && (self.surnameLabel != nil)) {
	    self.surnameLabel.text = [self.detailItem valueForKey:@"surname"];
		self.givenLabel.text = [self.detailItem valueForKey:@"givenName"];
		self.personIDLabel.text = [[self.detailItem valueForKey:@"personID"] stringValue];
		NSString *phone = [self.detailItem valueForKeyPath:@"person.cellPhone"];
		self.cellPhoneLabel.text = phone ? phone : @"";
		
		NSNumber *itemID =(NSNumber *)[self.detailItem valueForKey:@"itemTypeID"];
		self.itemIDLabel.text = [itemID stringValue];
		NSString *productName =  [self.detailItem valueForKeyPath:@"product.title"];
		self.itemNameLabel.text =  productName ? productName :[NSString stringWithFormat:@"Item ID %@", itemID];
		NSString *text = [NSString stringWithFormat:@"Item ID %@", itemID];
		self.numberLabel.text = [[self.detailItem valueForKey:@"itemNumber"] stringValue];
		text = [self.dateFormatter stringFromDate:[self.detailItem valueForKey:@"inTime"]];
		self.timeInLabel.text = text ? text : @"";
		text = [self.dateFormatter stringFromDate:[self.detailItem valueForKey:@"outTime"]];
		self.timeOutLabel.text = text ? text : @"";
		BOOL isSignIn = [[self.detailItem valueForKey:@"useType"] intValue] == kSignIn;
		BOOL isOut = [[self.detailItem valueForKey:@"isOut"] boolValue];
		self.withoutScanningButton.enabled = isOut;
		if (isOut)
		{
			self.outImageView.image = [UIImage imageNamed:(isSignIn ? @"signedIn" : @"out" )];
		}
		else
		{
			self.outImageView.image = [UIImage imageNamed:(isSignIn ? @"signedOut" : @"back" )];
		}
	}
}

// TODO: Manual checkin

- (IBAction)checkInAction:(id)sender
{
	[self.detailItem setValue:@(NO) forKey:@"isOut"];
	[self.detailItem setValue:[NSDate date] forKey:@"inTime"];
	[[AppDelegate myApp] setNeedsSave];
	[self configureView];
	
	[_master notifySignIn:(ItemUse *)self.detailItem isIn:NO];
}



@end
