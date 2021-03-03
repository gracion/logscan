//
//  SettingsViewController.h
//  LogScan
//
//  Created by Paul Collins on 12/26/20.
//  CCopyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISwitch *mattermostSwitch;
@property (weak, nonatomic) IBOutlet UITextField *serverTextField;
@property (weak, nonatomic) IBOutlet UITextField *userTextField;
@property (weak, nonatomic) IBOutlet UITextField *tokenTextField;

+ (NSDictionary *)mattermostSearchQuery;

- (IBAction)saveAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end

NS_ASSUME_NONNULL_END
