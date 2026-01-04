//
//  PeopleSearchPanelViewController.h
//  LogScan
//
//  Created by Paul Collins on 1/3/26.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "ScanViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface PeopleSearchPanelViewController : UIViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) ScanViewController *scanViewController;

@end

NS_ASSUME_NONNULL_END
