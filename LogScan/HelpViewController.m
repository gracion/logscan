//
//  HelpViewController.m
//  LogScan
//
//  Created by Paul A Collins on 3/3/16.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "HelpViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	// [self.textView setContentOffset:CGPointZero animated:YES]; didn't end up needing this but might later
	// Can't get scrolling to start at top unless I set the text after viewDidAppear
	if (_helpText)
		self.textView.text = _helpText;
	else
		self.textView.text = @"For help, visit https://gracion.com";
}
	
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)supportAction:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.gracion.com/logscan/"] options:@{} completionHandler:^(BOOL success) {
		;
	}];
}
@end
