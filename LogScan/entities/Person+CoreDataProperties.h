//
//  Person+CoreDataProperties.h
//  LogScan
//
//  Created by Paul A Collins on 11/8/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Person.h"

@class ItemUse;

NS_ASSUME_NONNULL_BEGIN

@interface Person (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *affiliation;
@property (nullable, nonatomic, retain) NSString *givenName;
@property (nullable, nonatomic, retain) NSNumber *level;
@property (nullable, nonatomic, retain) NSDate *modified;
@property (nullable, nonatomic, retain) NSNumber *personID;
@property (nullable, nonatomic, retain) NSString *surname;
@property (nullable, nonatomic, retain) NSString *cellPhone;
@property (nullable, nonatomic, retain) NSSet<ItemUse *>  *items;

@end

NS_ASSUME_NONNULL_END
