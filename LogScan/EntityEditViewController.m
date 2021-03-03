//
//  EntityEditViewController.m
//  LogScan
//
//  Add/Edit details of any scanned item or person
//  
//  Created by Paul A Collins on 6/20/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "EntityEditViewController.h"

@interface EntityEditViewController ()

@end

@implementation EntityEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	// prep UI
	self.nameField.text = [self.editObj valueForKey:@"surname"];
	self.givenNameField.text = [self.editObj valueForKey:@"givenName"];
	self.idField.text = [[self.editObj valueForKey:@"personID"] stringValue];

}

- (void)viewWillAppear:(BOOL)animated {
	[self.nameField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)acceptObjectToEdit:(NSManagedObject *)obj
{
	self.editObj = obj;
	// ui is not loaded let
}

- (IBAction)saveAction:(id)sender {
}

- (IBAction)cancelAction:(id)sender {
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.nameField)
		[self.givenNameField becomeFirstResponder];
	
	return YES;
}
@end
