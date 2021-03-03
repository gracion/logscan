//
//  ItemUse+CoreDataProperties.h
//  LogScan
//
//  Created by Paul A Collins on 11/8/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ItemUse.h"

@class Product;

NS_ASSUME_NONNULL_BEGIN

@interface ItemUse (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *givenName;
@property (nullable, nonatomic, retain) NSNumber *internalID;
@property (nullable, nonatomic, retain) NSDate *inTime;
@property (nullable, nonatomic, retain) NSNumber *isOut;
@property (nullable, nonatomic, retain) NSNumber *itemNumber;
@property (nullable, nonatomic, retain) NSNumber *itemTypeID;
@property (nullable, nonatomic, retain) NSDate *outTime;
@property (nullable, nonatomic, retain) NSNumber *personID;
@property (nullable, nonatomic, retain) NSString *surname;
@property (nullable, nonatomic, retain) Person *person;
@property (nullable, nonatomic, retain) Product *product;
@property (nullable, nonatomic, retain) NSNumber *useType;

@end

NS_ASSUME_NONNULL_END
