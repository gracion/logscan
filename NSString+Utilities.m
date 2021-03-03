//
//  NSString+Utilities.m
//  LogScan
//
//  Created by Paul A Collins on 11/8/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "NSString+Utilities.h"

@implementation NSString (Utilities)

- (NSString *)csvQuoted
{
	NSString *in = self;
	NSString *out = nil;
	if ([in rangeOfString:@"\""].location != NSNotFound)
	{
		in = [self stringByReplacingOccurrencesOfString:@"\"" withString:@"^"];
		out = in;
	}
	if ([in rangeOfString:@","].location != NSNotFound)
	{
		out = [NSString stringWithFormat:@"\"%@\"", self];
	}
	if (!out)
		out = [self copy];
	
	return out;
}


@end
