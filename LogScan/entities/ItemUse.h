//
//  ItemUse.h
//  LogScan
//
//  Created by Paul A Collins on 11/8/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

//  Entity (model class) representing one "use" of a physical item, such as a radio, or sign-in to
//  a location.
//  An ItemUse is created on checkout and updated on checkin. A second checkout of the same
//  physical item (represented by its barcode) is recorded in a new ItemUse instance.
//  This way, one ItemUse corresponds to one line of an ICS log form.
//  If you want something to be the model of the phyiscal item, consider its barcode-scanned string
//  to represent the item. That is stored in attributes "itemTypeID" and "itemNumber".
//
//  The Core data relationships with Person and Product are used with individual ItemUses to get
//  Related name data.
//  They could also be used to display all items used by a person or all persons with a product.


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Person;

NS_ASSUME_NONNULL_BEGIN

@interface ItemUse : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "ItemUse+CoreDataProperties.h"
