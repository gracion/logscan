//
//  FileImporter.m
//  LogScan
//
//  Created by Paul A Collins on 11/15/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "FileImporter.h"
#import "ItemUse.h"
#import "LogsViewController.h"
#import "Person.h"
#import "Product.h"

//TODO generalize to ImporterDelegate protocol
#import "AppDelegate.h"

NSString * const kCSVFileDateFormat = @"yyyy-MM-dd HH:mm";

@implementation FileImporter

#pragma mark - Utilities

- (NSDate *)dateForDateString:(NSString *)input
{
	NSDateFormatter *fmtr = [[NSDateFormatter alloc] init];
	
	[fmtr setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
	[fmtr setDateFormat:kCSVFileDateFormat];
	// We don't deal with time zones. I suppose you get local time zone.
	
	return [fmtr dateFromString:input];
}


- (NSMutableArray *)cellsFromLine:(NSString *)line
{
	// csv can quote commas, so... break into quoted and unquoted parts, then by comma in unquoted parts
	NSArray *qparts = [line componentsSeparatedByString:@"\""];
	// Product,101,2015-11-15,"Radio, Kenwood","Fake, Example",fake2,"Fake2, Example",fake3
	// { "Product,101,2015-11-15," "Radio, Kenwood", ",thingy"
	// 0-based, odd parts are quoted
	NSMutableArray *cells = [NSMutableArray arrayWithCapacity:8];
	for (NSInteger i = 0; i < [qparts count]; i++)
	{
		if (i % 2 == 0)
		{
			[cells addObjectsFromArray:[qparts[i] componentsSeparatedByString:@","]];
			if ([qparts count] > 1)
			{
				[cells removeLastObject]; // start of the quoted item
			}
			if (i > 1)
			{
				[cells removeObjectAtIndex:0]; // end of previous quoted item
			}
		}
		else
		{
			[cells addObject:qparts[i]]; // a quoted cell's contents
		}
	}
	return cells;
}

- (BOOL)importURL:(NSURL *)url dbController:(LogsViewController *)controller error:(NSError **)error
{
	NSString *csv = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
	if (csv) {
		// Each line starts with Person or Product, else ignore (such as headers)
		// Entity, ID, Modified, Title (product name), Surname, Given Name, Level (#), Affiliation,
		// Cell Phone, (todo:)Member Since
		NSArray *lines = [csv componentsSeparatedByString:@"\n"];
		NSInteger persCount = 0, prodCount = 0, entriesCount = 0;
		LogScanFileType type = PersonProductFileType;

		for (NSString *line in lines)
		{
			NSMutableArray *cells = [self cellsFromLine:line];
			if ([cells count] < 4)
			{
				NSLog(@"Ignored import line (not enough cells) %@", line);
			}
			// Parsed! what kind of row is this?
			else if ([[cells[0] lowercaseString] isEqualToString:@"person"])
			{
				if ([cells count] < 5)
				{
					NSLog(@"Ignored import line (person too few) %@", line);
				}
				else
				{
					NSInteger pid = [(NSString *)cells[1] integerValue];
					if (pid == 0)
						NSLog(@"Ignored import person (no or zero ID) %@", line);
					else
					{
						Person *person = [[AppDelegate myApp] findOrCreatePersonWithID:pid];
						
						person.modified = [self dateForDateString:cells[2]];
						if (person.modified == nil)
						{
							person.modified = [NSDate date]; // now
						}
						// col 3 is title, currently only used in products
						person.surname = cells[4];
						if ([cells count] >= 6)
						{
							person.givenName = cells[5];
						}
						if ([cells count] >= 7)
						{
							person.level = @([(NSString *)cells[6] integerValue]);
						}
						if ([cells count] >=8)
						{
							person.affiliation = cells[7];
						}
						if ([cells count] >=9)
						{
							person.cellPhone = cells[8];
						}
						// TODO 9th column: MemberSince
						
						persCount++;
					}
				}
			}
			else if ([[cells[0] lowercaseString] isEqualToString:@"product"])
			{
				if ([cells count] < 4)
				{
					NSLog(@"Ingored inport line (product too few) %@", line);
				}
				else
				{
					NSInteger pid = [(NSString *)cells[1] integerValue];
					if (pid == 0)
						NSLog(@"Ignored import person (no or zero ID) %@", line);
					else
					{
						Product *product = [[AppDelegate myApp] findOrCreateProductWithID:pid];
						product.modified = [self dateForDateString:cells[2]];
						product.title = cells[3];
						prodCount++;
					}
				}
			}
			else if ([[cells[0] lowercaseString] isEqualToString:@"entity"])
			{
				; // normal headers, ignore unless we need to parse them someday
			}
			else if ([[cells[0] lowercaseString] isEqualToString:@"date out"])
			{
				type = LogEntriesFileType;
				break;
			}
			else
				NSLog(@"Ignored import line (unknown type) %@", line);
		}
		
		if (type == LogEntriesFileType)
		{
			for (NSString *line in lines)
			{
				NSMutableArray *cells = [self cellsFromLine:line];
				if ([cells count] < 8)
				{
					NSLog(@"Ignored import line (not enough cells) %@", line);
				}
				// Parsed! First skip over the header
				else if ([[cells[0] lowercaseString] isEqualToString:@"date out"])
				{
					continue;
				}
				else
				{
					entriesCount++;
					Product *product = [[AppDelegate myApp] findOrCreateProductWithID:[(NSString *)cells[4] integerValue]];
					Person *person = [[AppDelegate myApp] findOrCreatePersonWithID:[(NSString *)cells[7] integerValue]];
					ItemUse *iuse = [NSEntityDescription insertNewObjectForEntityForName:@"ItemUse" inManagedObjectContext:controller.managedObjectContext];
					// If person or product name missing, get from log import
					// Person name goes to both ItemUse and Person
					NSString *given = person.givenName;
					if ([given length] > 0)
						iuse.givenName = given;
					else if ([cells count] > 9)
					{
						person.givenName = (NSString *)cells[9];
						iuse.givenName = person.givenName;
					}
					else
					{
						iuse.givenName = @"";
					}
					NSString *sur = person.surname;
					if ([sur length] > 0)
						iuse.surname = sur;
					else if ([cells count]> 8)
					{
						person.surname =(NSString *)cells[8];
						iuse.surname = person.surname;
					}
					else
						iuse.surname = @"";
					
					// Product name is only in product
					NSString *title = product.title;
					if ([title length] == 0)
						product.title = cells[6];
					
					iuse.itemTypeID = @([(NSString *)cells[4] integerValue]);
					iuse.itemNumber = @([(NSString *)cells[5] integerValue]);
					NSString *dateStr = [NSString stringWithFormat:@"%@ %@", cells[0], cells[1]];
					iuse.outTime = [self dateForDateString:dateStr];
					dateStr = [NSString stringWithFormat:@"%@ %@", cells[2], cells[3]];
					if ([dateStr length] > 13) // skip unless full date
					{
						iuse.inTime = [self dateForDateString:dateStr];
						iuse.isOut = @(NO);
					}
					else
						iuse.isOut = @(YES);
					
					iuse.product = product;
					iuse.person = person;
				}
			}
		}
		
		// import complete
		[[AppDelegate myApp] saveContext];
		if (type == PersonProductFileType)
			NSLog(@"Imported %ld products, %ld persons", (long)prodCount, (long)persCount);
		else
			NSLog(@"Imported %ld log entries", (long)entriesCount);
				  
		return (persCount > 0 || prodCount > 0 || entriesCount > 0);
	}
	return NO;	
}


@end
