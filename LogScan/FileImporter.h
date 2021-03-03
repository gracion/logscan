//
//  FileImporter.h
//  LogScan
//
//  Created by Paul A Collins on 11/15/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import <Foundation/Foundation.h>

@class AppDelegate;
@class LogsViewController;

typedef enum : NSUInteger {
	PersonProductFileType,
	LogEntriesFileType
} LogScanFileType;

@interface FileImporter : NSObject

- (BOOL)importURL:(NSURL *)url dbController:(LogsViewController *)controller error:(NSError **)error;

@end
