//
//  DetailViewController.h
//  LogScan
//
//  Created by Paul A Collins on 4/23/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class LogsViewController;

@interface DetailViewController : UIViewController

@property (strong, nonatomic) NSManagedObject *detailItem;
@property (weak, nonatomic) IBOutlet UILabel *surnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *givenLabel;
@property (weak, nonatomic) IBOutlet UILabel *personIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeInLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeOutLabel;
@property (weak, nonatomic) IBOutlet UIImageView *outImageView;
@property (weak, nonatomic) IBOutlet UIButton *withoutScanningButton;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, weak) LogsViewController *master;

- (IBAction)checkInAction:(id)sender;

@end

