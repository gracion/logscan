//
//  HelpViewController.h
//  LogScan
//
//  Created by Paul A Collins on 3/3/16.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) NSString *helpText;


- (IBAction)supportAction:(id)sender;

@end
