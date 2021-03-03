//
//  Server+CoreDataProperties.h
//  LogScan
//
//  Created by Paul A Collins on 11/8/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Server.h"

NS_ASSUME_NONNULL_BEGIN

@interface Server (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *keychainID;
@property (nullable, nonatomic, retain) NSDate *lastDownload;
@property (nullable, nonatomic, retain) NSDate *modified;
@property (nullable, nonatomic, retain) NSString *uri;
@property (nullable, nonatomic, retain) NSString *username;

@end

NS_ASSUME_NONNULL_END
