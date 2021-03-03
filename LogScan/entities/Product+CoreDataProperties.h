//
//  Product+CoreDataProperties.h
//  LogScan
//
//  Created by Paul A Collins on 11/8/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Product.h"

@class ItemUse;

NS_ASSUME_NONNULL_BEGIN

@interface Product (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *modified;
@property (nullable, nonatomic, retain) NSNumber *productID;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSSet<ItemUse *> *itemUses;
@property (nullable, nonatomic, retain) NSNumber *isLocation;
@property (nullable, nonatomic, retain) NSNumber *latitude;
@property (nullable, nonatomic, retain) NSNumber *longitude;

@end

@interface Product (CoreDataGeneratedAccessors)

- (void)addItemUsesObject:(ItemUse *)value;
- (void)removeItemUsesObject:(ItemUse *)value;
- (void)addItemUses:(NSSet<ItemUse *> *)values;
- (void)removeItemUses:(NSSet<ItemUse *> *)values;

@end

NS_ASSUME_NONNULL_END
