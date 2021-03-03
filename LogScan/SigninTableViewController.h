//
//  SigninTableViewController.h
//  LogScan
//
//  Created by Paul Collins on 11/29/20.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "LogsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SigninTableViewController : LogsViewController

@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

NS_ASSUME_NONNULL_END
