//
//  SigninRootViewController.m
//  LogScan
//
//  Created by Paul Collins on 5/15/22.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "SigninRootViewController.h"

#import "SigninTableViewController.h"

@interface SigninRootViewController ()

@property (weak, nonatomic) SigninTableViewController* signinTableVC;

@end

@implementation SigninRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact)
	{
		[self insertScanButton];
	}
}


- (void)insertScanButton
{
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
								  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
								  target:self
								  action:@selector(addAction:)];
	self.navigationItem.rightBarButtonItem = addButton;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	if (previousTraitCollection.horizontalSizeClass != self.traitCollection.horizontalSizeClass)
	{
		if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact)
		{
			[self insertScanButton];
		}
		else
		{
			self.navigationItem.rightBarButtonItem = nil;
		}
	}
}


#pragma mark - Navigation

- (void)addAction:(id)sender
{
	[self performSegueWithIdentifier: @"showSigninScanner" sender: self];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"tableContainer"])
    {
		self.signinTableVC = (SigninTableViewController *)[segue destinationViewController];
		self.signinTableVC.managedObjectContext = self.managedObjectContext;
	}
	else if ([[segue destinationViewController] isKindOfClass:[ScanViewController class]])
	{
		[(ScanViewController *)[segue destinationViewController] setMyMaster:self.signinTableVC];
	}
}


@end
