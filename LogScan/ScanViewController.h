//
//  ScanViewController.h
//  LogScan
//
//  Created by Paul A Collins on 4/25/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

typedef enum : NSUInteger {
	ScannedPerson,
	ScannedPersonID,
	ScannedItem,
	ScanUnknown,
	ScanResultDeferred
} ScanResult;


@class LogsViewController;
@class AVSpeechSynthesizer;
@class Person;
@class Product;

@interface ScanViewController : UIViewController {
}

@property (weak, nonatomic) IBOutlet UIView *readerView;
@property (weak, nonatomic) IBOutlet UITextField *scanTextField;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *personIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *resultText;
@property (weak, nonatomic) IBOutlet UIImageView *inOutView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@property (weak, nonatomic) LogsViewController *myMaster;

@property (assign, nonatomic) BOOL wasLogged; // NO until committed
@property (assign, nonatomic) BOOL wentOut;
@property (assign, nonatomic) NSInteger personID;
@property (assign, nonatomic) NSInteger itemNumber;
@property (assign, nonatomic) NSInteger itemTypeID;
@property (strong, nonatomic) NSString *surname;
@property (strong, nonatomic) NSString *givenName;

@property (assign, nonatomic) ScanResult lastScanResult;
@property (strong, nonatomic) NSString *lastScanData;
@property (strong, nonatomic) AVSpeechSynthesizer *synth;

@property (strong, nonatomic) Person *personObj;
@property (strong, nonatomic) Product *productObj;

- (IBAction)clearAction:(id)sender;
- (IBAction)closeAction:(id)sender;
- (IBAction)teamButtonAction:(id)sender;
- (IBAction)switchCameraAction:(id)sender;


@end
