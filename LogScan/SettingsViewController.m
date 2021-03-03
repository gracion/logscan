//
//  SettingsViewController.m
//  LogScan
//
//  Created by Paul Collins on 12/26/20.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "SettingsViewController.h"

#import "AppDelegate.h"

#include <Security/SecBase.h>

@interface SettingsViewController ()

@property (strong, nonatomic) NSString *serverAddr;
@property (strong, nonatomic) NSString *userName;

@end

@implementation SettingsViewController
{
	OSStatus _secReadStatus;
}

+ (void)initialize
{
	if (self == [SettingsViewController class])
	{
		NSDictionary *defs = @{@"mattermostNotifyOn": @(NO)};
		[[NSUserDefaults standardUserDefaults] registerDefaults:defs];
	}
}


+ (NSDictionary *)mattermostSearchQuery {
	NSDictionary *query = @{(__bridge NSString *)kSecClass : (__bridge NSString *)kSecClassGenericPassword,
							(__bridge NSString *)kSecAttrLabel : @"LogScan Mattermost token",
							(__bridge NSString *)kSecReturnData : @(YES), (__bridge NSString *)kSecReturnAttributes : @(YES)};
	return query;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    BOOL notifyOn = [defs boolForKey:@"mattermostNotifyOn"];
    self.mattermostSwitch.on = notifyOn;

	CFTypeRef result;
	_secReadStatus = SecItemCopyMatching((__bridge CFDictionaryRef)[self.class mattermostSearchQuery],  &result);
    NSLog(@"SecItemCopyMatching returned %d", (int)_secReadStatus);

	if (_secReadStatus == errSecSuccess && result)
	{
		self.serverAddr = (__bridge NSString *)CFDictionaryGetValue( result, kSecAttrService );
		self.userName =(__bridge NSString *)CFDictionaryGetValue( result, kSecAttrAccount );
		NSData *tokenData = (__bridge NSData *)CFDictionaryGetValue( result, kSecValueData );
		NSString *token = [[NSString alloc] initWithData:tokenData encoding:NSUTF8StringEncoding];
		
		self.serverTextField.text = _serverAddr;
		self.userTextField.text = _userName;
		self.tokenTextField.text = token;

		CFRelease( result );
	}
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancelAction:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)saveAction:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:_mattermostSwitch.on forKey:@"mattermostNotifyOn"];
	NSString *server = [self.serverTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *user = self.userTextField.text;
	NSData *tokenData = [self.tokenTextField.text dataUsingEncoding:NSUTF8StringEncoding];
	
	OSStatus ok;
	NSString *userError = nil;
	
	// Dictionaries with multiple uses
	NSDictionary *query = @{(__bridge NSString *)kSecClass : (__bridge NSString *)kSecClassGenericPassword,
							(__bridge NSString *)kSecAttrLabel : @"LogScan Mattermost token",
							(__bridge NSString *)kSecAttrAccount : user,
							(__bridge NSString *)kSecAttrService : server};
	// Update the token in a pre-stored item
	NSDictionary *tokenUpdate = @{(__bridge NSString *)kSecValueData : tokenData};

	if (_secReadStatus == errSecSuccess && [server isEqualToString:_serverAddr] && [user isEqualToString:_userName])
	{
		ok = SecItemUpdate( (__bridge CFDictionaryRef)query, (CFDictionaryRef)tokenUpdate );
		NSLog(@"SecItemUpdate (token only) returned %d", (int)ok); // return errors in SecBase.h  0 is ok
		if (ok != errSecSuccess)
		{
			userError = @"Failed to update token in Keychain.";
		}
	}
	else
	{
		// Save under a new user/server
		if (_secReadStatus == errSecSuccess)
		{
			// delete the old record under the other user/server combo, which has changed
			NSDictionary *deleteQuery = @{(__bridge NSString *)kSecClass : (__bridge NSString *)kSecClassGenericPassword,
									(__bridge NSString *)kSecAttrLabel : @"LogScan Mattermost token",
									(__bridge NSString *)kSecAttrAccount : _userName,
									(__bridge NSString *)kSecAttrService : _serverAddr};
			ok = SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
			NSLog(@"SecItemDelete returned %d", (int)ok);
		}
		
		if ([user length] || [server length] || [tokenData length])
		{
			// add or update the new user/server (shouldn't exist because we delete any other one above,
			// but to be safe, check anyway)
			CFTypeRef result;
			ok = SecItemCopyMatching((__bridge CFDictionaryRef)query,  &result);
			NSLog(@"SecItemCopyMatching (for save) returned %d", (int)ok);
			
			if (ok == errSecSuccess)
			{
				// Unexpectedly exists! update token
				ok = SecItemUpdate( (__bridge CFDictionaryRef)query, (CFDictionaryRef)tokenUpdate );
				NSLog(@"SecItemUpdate (old user found, token only) returned %d", (int)ok);
				if (ok != errSecSuccess)
				{
					userError = @"Failed to store token in Keychain.";
				}
			}
			else
			{
				// does not exist, add new Keychain entry
				NSDictionary *item = @{(__bridge NSString *)kSecClass : (__bridge NSString *)kSecClassGenericPassword,
									   (__bridge NSString *)kSecValueData : tokenData,
									   (__bridge NSString *)kSecAttrAccount : user,
									   (__bridge NSString *)kSecAttrLabel : @"LogScan Mattermost token",
									   (__bridge NSString *)kSecAttrService : server};
				
				ok = SecItemAdd((CFDictionaryRef)item, NULL);
				NSLog(@"SecItemAdd returned %d", (int)ok); // return errors in SecBase.h  0 is ok
				if (ok != errSecSuccess)
				{
					userError = @"Failed to store new token in Keychain.";
				}
			}
		}
		else
		{
			// all fields empty - no further action
		}
	}
	if (userError)
	{
		// This viewcontroller is going away, have the app do it
		[[AppDelegate myApp] deferredWarningAlert:userError];
	}

	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end

