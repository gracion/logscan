//
//  UtilityViewController.h
//  LogScan
//
//  Created by Paul A Collins on 10/25/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <UIKit/UIKit.h>

@class LogsViewController;

typedef enum : NSUInteger {
	kText = 0,
	kFile = 1
} ExportType;

typedef enum: NSUInteger {
	kPersonAndData	= 1,
	kItemUses		= 2,
	kSignIns		= 4
} DataType;

@interface SendViewController : UIViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) IBOutlet UITabBarItem *sendTabBarItem;
@property (weak, nonatomic) IBOutlet UISwitch *inventorySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *signInSwitch;
@property (weak, nonatomic) IBOutlet UIButton *clearAllButton;
@property (weak, nonatomic) IBOutlet UIButton *sendReportButton;
@property (weak, nonatomic) IBOutlet UILabel *googleStatusLabel;
@property (weak, nonatomic) IBOutlet UITextField *eventNameField;
@property (weak, nonatomic) IBOutlet UIButton *defaultHoursPopUp;
@property (weak, nonatomic) IBOutlet UITextField *defaultHoursField;
@property (weak, nonatomic) IBOutlet UIView *googleControlsView;

- (IBAction)exportPersonProductData:(id)sender;
// Request to clear log entries, with are you sure.
- (IBAction)clearLogEntries:(id)sender;
- (IBAction)exportAction:(id)sender;
- (IBAction)sendToGoogleAction:(id)sender;

#pragma mark - Data Utilities

// Immediately clear them
- (void)clearAllLogEntries;

@end
