//
//  SigninRootViewController.h
//  LogScan
//
//  Created by Paul Collins on 5/15/22.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SigninRootViewController : UIViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

NS_ASSUME_NONNULL_END
