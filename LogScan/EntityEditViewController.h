//
//  EntityEditViewController.h
//  LogScan
//
//  Created by Paul A Collins on 6/20/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface EntityEditViewController : UIViewController

@property (strong, nonatomic) NSManagedObject *editObj;
@property (weak, nonatomic) IBOutlet UILabel *idField;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *givenNameField;
@property (weak, nonatomic) IBOutlet UITextField *phoneField;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *givenLabel;

- (void)acceptObjectToEdit:(NSManagedObject *)obj;
- (IBAction)saveAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
