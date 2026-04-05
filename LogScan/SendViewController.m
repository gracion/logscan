//
//  UtilityViewController.m
//  LogScan
//
//  Created by Paul A Collins on 10/25/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "SendViewController.h"

#import "AppDelegate.h"
#import "Person+CoreDataProperties.h"
#import "Product+CoreDataProperties.h"
#import "ItemUse+CoreDataProperties.h"

extern NSString * const kCSVFileDateFormat;

@interface SendViewController () <UITextFieldDelegate>

@property (nonatomic) CGFloat originalViewOriginY;
@property (nonatomic) BOOL viewIsShifted;

@end

@implementation SendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.googleStatusLabel.text = @"";
	self.defaultHoursField.delegate = self;
	self.eventNameField.delegate = self;
	[self configureDefaultHoursPopUp];

	NSString *savedEvent = [[NSUserDefaults standardUserDefaults] stringForKey:@"eventName"];
	if (savedEvent)
		self.eventNameField.text = savedEvent;
	
	UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
		  initWithTarget:self action:@selector(copyStatusLabel:)];
	  [self.googleStatusLabel addGestureRecognizer:lp];
	  self.googleStatusLabel.userInteractionEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	NSDictionary *info = notification.userInfo;
	CGRect kbFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve = [info[UIKeyboardAnimationCurveUserInfoKey] integerValue];

	if (!self.viewIsShifted)
		self.originalViewOriginY = self.view.frame.origin.y;

	CGFloat deadSpace = CGRectGetMaxY(self.view.bounds) - CGRectGetMaxY(self.googleControlsView.frame);
	CGFloat newY = self.originalViewOriginY - kbFrame.size.height + deadSpace;
	self.viewIsShifted = YES;

	[UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
		CGRect frame = self.view.frame;
		frame.origin.y = newY;
		self.view.frame = frame;
	} completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	NSDictionary *info = notification.userInfo;
	NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve = [info[UIKeyboardAnimationCurveUserInfoKey] integerValue];

	self.viewIsShifted = NO;

	// Match the keyboard's animation curve
	[UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
		CGRect frame = self.view.frame;
		frame.origin.y = self.originalViewOriginY;
		self.view.frame = frame;
	} completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)copyStatusLabel:(UILongPressGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateBegan)
	{
		[UIPasteboard generalPasteboard].string = self.googleStatusLabel.text;
		self.googleStatusLabel.alpha = 0.2;
		[UIView animateWithDuration:0.6 animations:^{
			self.googleStatusLabel.alpha = 1.0;
		}];
	}
}


#pragma mark - Default Hours

- (void)configureDefaultHoursPopUp
{
	double current = [[NSUserDefaults standardUserDefaults] doubleForKey:@"defaultHours"];
	self.defaultHoursField.text = [NSString stringWithFormat:@"%g", current];

	NSArray<NSNumber *> *options = @[@0.5, @1.0, @1.5, @2.0, @2.5, @3.0, @4.0, @5.0, @6.0, @8.0];
	NSMutableArray<UIAction *> *actions = [NSMutableArray array];
	__weak SendViewController *weakSelf = self;

	for (NSNumber *opt in options) {
		double val = opt.doubleValue;
		[actions addObject:[UIAction actionWithTitle:[NSString stringWithFormat:@"%g", val]
											  image:nil identifier:nil
											handler:^(__kindof UIAction *a) {
			[weakSelf applyDefaultHours:val];
		}]];
	}

	self.defaultHoursPopUp.menu = [UIMenu menuWithTitle:@"" children:actions];
	self.defaultHoursPopUp.showsMenuAsPrimaryAction = YES;
}

- (void)applyDefaultHours:(double)hours
{
	if (hours < 0.5) hours = 0.5;
	[[NSUserDefaults standardUserDefaults] setDouble:hours forKey:@"defaultHours"];
	[self configureDefaultHoursPopUp];
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == self.defaultHoursField)
	{
		double val = [textField.text doubleValue];
		[self applyDefaultHours:val];
	}
	else if (textField == self.eventNameField)
	{
		NSString *name = [textField.text stringByTrimmingCharactersInSet:
						  [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"eventName"];
		[[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSinceReferenceDate]
												  forKey:@"eventNameTimestamp"];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}


// Export the person and product tables as a csv file
- (IBAction)exportPersonProductData:(id)sender
{
	[self export:kPersonAndData inMode:[sender tag] == 1 ? kFile : kText];
}

// Clear all items from log (both?)
- (IBAction)clearLogEntries:(id)sender
{
	CGRect rect = self.clearAllButton.frame;
	[self askUser:@"Are you sure you want to clear all log entries?" actionTitle:@"Clear All" cancelTitle:@"Cancel" destructive:YES onViewController:self inRect:rect];
}


#pragma mark - Exporting

- (IBAction)exportAction:(id)sender
{
	DataType type = self.inventorySwitch.on ? kItemUses : 0;
	if (self.signInSwitch.on)
	{
		type += kSignIns;
	}
	[self export:type inMode:kFile];
}


- (IBAction)sendToGoogleAction:(id)sender
{
	static const NSTimeInterval kEventNameMaxAge = 18 * 3600;
	double ts = [[NSUserDefaults standardUserDefaults] doubleForKey:@"eventNameTimestamp"];
	NSTimeInterval age = [[NSDate date] timeIntervalSinceReferenceDate] - ts;

	BOOL isEmpty = self.eventNameField.text.length == 0;
	BOOL isStale = ts == 0 || age > kEventNameMaxAge;
	if (isEmpty || isStale)
	{
		NSString *current = self.eventNameField.text;
		NSString *message = isEmpty
			? @"No event name has been entered."
			: @"The event name hasn't been updated in over 18 hours.";
		UIAlertController *alert = [UIAlertController
			alertControllerWithTitle:@"Confirm Event Name"
							 message:message
					  preferredStyle:UIAlertControllerStyleAlert];
		[alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
			tf.text = current;
			tf.placeholder = @"Event name";
		}];
		__weak SendViewController *weakSelf = self;
		[alert addAction:[UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault
											   handler:^(UIAlertAction *a) {
			NSString *name = [alert.textFields.firstObject.text
				stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			weakSelf.eventNameField.text = name;
			[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"eventName"];
			[[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSinceReferenceDate]
													  forKey:@"eventNameTimestamp"];
			[weakSelf proceedWithGoogleSend];
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
		return;
	}

	[self proceedWithGoogleSend];
}

- (void)proceedWithGoogleSend
{
	self.googleStatusLabel.text = @"Sending...";
	NSString *csv = [self csvFromItemUses:kSignIn];
	NSError *err = nil;
	NSArray<NSString*> *rows = [self jsonBodyFromSimpleCSV:csv error:&err];
	if (err)
	{
		self.googleStatusLabel.text = [NSString stringWithFormat:@"Internal data error: %@",
									   [err localizedDescription]];
	}
	else if ([rows count])
	{
		NSString *scriptKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"googleKey"];
		if ([scriptKey length] == 0)
		{
			self.googleStatusLabel.text = @"Google key missing from settings";
			return;
		}
		NSDictionary *payload = @{ @"secret" : scriptKey, @"rows" : rows };

		NSError *jErr = nil;
		NSData *json = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jErr];

		if (!json) {
			self.googleStatusLabel.text = [NSString stringWithFormat:
					@"JSON serialization failed: %@", [jErr localizedDescription]];
			return;
		}

		[self uploadJson:json];
	}
}


- (void)uploadJson:(NSData *)jsonData
{
	NSString *gURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"googleURL"];
	NSURL *url = [NSURL URLWithString:gURL ? gURL : @""];
	
	if (!url)
	{
		self.googleStatusLabel.text = @"Google url missing or malformed";
		return;
	}

	// Build request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	request.HTTPMethod = @"POST";
	request.HTTPBody = jsonData;
	request.timeoutInterval = 30.0;

	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

	// Use default session; it follows redirects automatically
	NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

	NSURLSessionDataTask *task =
	[session dataTaskWithRequest:request
				completionHandler:^(NSData * _Nullable data,
									NSURLResponse * _Nullable response,
									NSError * _Nullable error)
	{
		NSString *rtnData = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"(no data)";

		if (error)
		{
				dispatch_async(dispatch_get_main_queue(), ^{
					self.googleStatusLabel.text = [NSString stringWithFormat:@"Internal task error: %@",
												   [error localizedDescription]];
				});
			return;
		}

		NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
		NSInteger status = http.statusCode;

		if (status < 200 || status >= 300)
		{
			NSString *bodyText = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
			NSError *statusError =
				[NSError errorWithDomain:@"Upload"
									code:status
								userInfo:@{NSLocalizedDescriptionKey :
											   [NSString stringWithFormat:@"HTTP %ld %@", (long)status, bodyText ?: @""]}];

				dispatch_async(dispatch_get_main_queue(), ^{
					self.googleStatusLabel.text = [NSString stringWithFormat:@"Cloud error: %@",
												   [statusError localizedDescription]];
				});
			return;
		}

		// Optional: parse JSON response { ok: true, appended: N }
		if (data.length > 0)
		{
			NSDictionary *resp =
				[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
			if (!resp)
			{
				NSString *rtn = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
				dispatch_async(dispatch_get_main_queue(), ^{
					self.googleStatusLabel.text = [NSString stringWithFormat:@"Server error: %@", rtn];
				});
				return;
			}
			if ([resp isKindOfClass:[NSDictionary class]] &&
				[resp[@"ok"] respondsToSelector:@selector(boolValue)] &&
				![resp[@"ok"] boolValue])
			{
				NSError *apiError =
					[NSError errorWithDomain:@"Upload"
										code:-2
									userInfo:@{NSLocalizedDescriptionKey : @"Server returned ok=false"}];
					dispatch_async(dispatch_get_main_queue(), ^{
						self.googleStatusLabel.text = [NSString stringWithFormat:@"API error: %@",
													   [apiError localizedDescription]];

					});
				return;
			}
		}

			dispatch_async(dispatch_get_main_queue(), ^{
				NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
				formatter.dateStyle = NSDateFormatterMediumStyle;
				formatter.timeStyle = NSDateFormatterShortStyle;
				NSString *aDate = [formatter stringFromDate:[NSDate date]];
				
				self.googleStatusLabel.text = [NSString stringWithFormat:@"Upload OK (%@)", aDate];
			});
	}];

	[task resume];
}


/// Convert a simple positional CSV string into Apps Script JSON:
/// { "rows": [ [DateIn, TimeIn, DateOut, TimeOut, PersonID, Surname, GivenName, CellPhone, hours,
///  Event Name], ... ] }
///
/// Assumptions:
/// - First non-empty line is a header
/// - No quotes
/// - No commas inside fields
/// - Exactly 10 columns expected
- (NSArray<NSString*> *)jsonBodyFromSimpleCSV:(NSString *)csv
							error:(NSError * __autoreleasing *)errorOut
{
	if (csv.length == 0) {
		if (errorOut) {
			*errorOut = [NSError errorWithDomain:@"CSVtoJSON"
											code:1
										userInfo:@{NSLocalizedDescriptionKey : @"CSV is empty"}];
		}
		return nil;
	}

	// Split into non-empty lines
	NSArray<NSString *> *rawLines =
		[csv componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	NSMutableArray<NSString *> *lines = [NSMutableArray array];
	for (NSString *line in rawLines) {
		NSString *trim =
			[line stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (trim.length > 0) {
			[lines addObject:trim];
		}
	}

	if (lines.count < 2) {
		if (errorOut) {
			*errorOut = [NSError errorWithDomain:@"CSVtoJSON"
											code:2
										userInfo:@{NSLocalizedDescriptionKey :
											@"CSV must contain header + at least one data row"}];
		}
		return nil;
	}

	// Skip header row
	NSMutableArray<NSArray<NSString *> *> *rows = [NSMutableArray array];

	for (NSUInteger i = 1; i < lines.count; i++) {
		NSArray<NSString *> *parts = [lines[i] componentsSeparatedByString:@","];

		NSMutableArray<NSString *> *row = [NSMutableArray arrayWithCapacity:10];
		for (NSUInteger c = 0; c < 10; c++) {
			NSString *v = (c < parts.count) ? parts[c] : @"";
			v = [v stringByTrimmingCharactersInSet:
					[NSCharacterSet whitespaceCharacterSet]];

			if ([v isEqualToString:@"(null)"]) {
				v = @"";
			}
			[row addObject:v];
		}

		[rows addObject:row];
	}

	return [NSArray arrayWithArray:rows];
}


- (void)export:(DataType)dt inMode:(ExportType)mode
{
	//Create an activity view controller with the url container as its activity item.
	
	NSError *err = nil;
	// We'll just create the csv and deliver it
	[self fixNamesInItemUses];
	NSMutableArray *csvs = [NSMutableArray arrayWithCapacity:2];
	NSMutableArray<NSNumber *> *types = [NSMutableArray arrayWithCapacity:2];
	
	if (dt & kPersonAndData)
	{
		[csvs addObject:[self csvFromPersonsAndProducts]];
		[types addObject:@(kPersonAndData)];
	}
	if (dt & kSignIns)
	{
		NSString *csv = [self csvFromItemUses:kSignIn];
		if (csv.length > 0)
		{
			[csvs addObject:csv];
			[types addObject:@(kSignIns)];
		}
	}
	if (dt & kItemUses)
	{
		NSString *csv = [self csvFromItemUses:kInventory];
		if (csv.length > 0)
		{
			[csvs addObject:csv];
			[types addObject:@(kItemUses)];
		}
	}
	NSMutableArray *activityItems = [NSMutableArray arrayWithCapacity:2];

	if (mode != kText)
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *cacheDirs = [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
		if ([cacheDirs count])
		{
			NSURL *cd = cacheDirs[0];
			NSURL *dirPath = [cd URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
			// If the directory does not exist, this method creates it.
			// This method is only available in OS X v10.7 and iOS 5.0 or later.
			NSError*    theError = nil;
			if ([fm createDirectoryAtURL:dirPath withIntermediateDirectories:YES attributes:nil error:&theError])
			{
				// created or exists
				for (NSUInteger i = 0; i < [csvs count]; i++)
				{
					// See enum DataType
					NSString *name = @[@"LogScanPersonsAndProducts.csv", @"Logistics.csv", @"", @"SignIn.csv"][types[i].intValue - 1];
					NSURL *filePath = [dirPath URLByAppendingPathComponent:name];
					NSString *csv = csvs[i];
					if ([csv writeToURL:filePath atomically:NO encoding:NSUTF8StringEncoding error:&err])
					{
						[activityItems addObject:filePath];
					}
					else
					{
						NSLog(@"Error writing csv cache file: %@", [err localizedDescription]);
					}
				}
			}
		}
	}

	if (!activityItems)
		activityItems = csvs;
	
	
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
	activityViewController.popoverPresentationController.sourceView = self.sendReportButton;
	[self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Data Utilities

// Currently, this only handles the answer to the alert for clearLogEntries
// Also this is the only controller
- (void)performOnAnswer:(BOOL)answer onController:(SendViewController *)mvc
{
	if (answer == YES)
	{
		[mvc clearAllLogEntries];
	}
}


- (void)clearAllLogEntries
{
	NSArray *objs = [[AppDelegate myApp] allItemsOfType:kAny];
	for (NSManagedObject *obj in objs)
	{
		[_managedObjectContext deleteObject:obj];
	}
	[[AppDelegate myApp] saveContext];
}


- (NSString *)csvFromItemUses:(UseType)useType;
{
	NSDateFormatter *dateFmtr = [[NSDateFormatter alloc] init];
	[dateFmtr setDateFormat:@"yyyy-MM-dd"];
	NSDateFormatter	*timeFmtr = [[NSDateFormatter alloc] init];
	[timeFmtr setDateFormat:@"HH:mm"];
	
	// get everything, sorted by time out, and put into csv
	NSArray *objs = [[AppDelegate myApp] allItemsOfType:useType];
	
	NSMutableString *str;
	if ( useType == kInventory)
	{
		str = [[NSMutableString alloc] initWithString:@"Date Out,Time Out,Date In,Time In,ItemTypeID,ItemNumber,ItemName,PersonID,Surname,Given Name,Cell Phone\n"];
		
		for (NSManagedObject *obj in objs)
		{
			NSDate *inTime = [obj valueForKey:@"inTime"];
			NSNumber *itemID =(NSNumber *)[obj valueForKey:@"itemTypeID"];
			NSString *productName = [obj valueForKeyPath:@"product.title"];
			
			NSString *line = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
							  [dateFmtr stringFromDate:[obj valueForKey:@"outTime"]],
							  [timeFmtr stringFromDate:[obj valueForKey:@"outTime"]],
							  inTime ? [dateFmtr stringFromDate:[obj valueForKey:@"inTime"]] : @"",
							  inTime ? [timeFmtr stringFromDate:[obj valueForKey:@"inTime"]] : @"",
							  [itemID stringValue],
							  [[obj valueForKey:@"itemNumber"] stringValue],
							  productName,
							  [[obj valueForKey:@"personID"]  stringValue],
							  [obj valueForKey:@"surname"],
							  [obj valueForKey:@"givenName"],
							  [obj valueForKeyPath:@"person.cellPhone"]];
			[str appendString:line];
		}
	}
	else
	{
		// signin
		str = [[NSMutableString alloc] initWithString:@"Date In,Time In,Date Out,Time out,PersonID,Surname,Given Name,Cell Phone,hours,Event Name\n"];

		double defaultHours = [[NSUserDefaults standardUserDefaults] doubleForKey:@"defaultHours"];

		NSString *eventName = [self.eventNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		for (NSManagedObject *obj in objs)
		{
			NSDate *inTime = [obj valueForKey:@"inTime"];

			double hours = defaultHours;
			if (inTime)
			{
				double rawHours = [inTime timeIntervalSinceDate:[obj valueForKey:@"outTime"]] / 3600.0;
				if (rawHours >= 0.1)
					hours = round(rawHours * 10.0) / 10.0;
			}

			NSString *line = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%.1f,%@\n",
							  // Remember, these are reversed meaning for signins
							  [dateFmtr stringFromDate:[obj valueForKey:@"outTime"]],
							  [timeFmtr stringFromDate:[obj valueForKey:@"outTime"]],
							  inTime ? [dateFmtr stringFromDate:[obj valueForKey:@"inTime"]] : @"",
							  inTime ? [timeFmtr stringFromDate:[obj valueForKey:@"inTime"]] : @"",
							  [[obj valueForKey:@"personID"]  stringValue],
							  [obj valueForKey:@"surname"],
							  [obj valueForKey:@"givenName"],
							  [obj valueForKeyPath:@"person.cellPhone"],
							  hours,
							  eventName];
			[str appendString:line];
		}

	}
	return str;
}


- (BOOL)fixNamesInItemUses
{
	NSInteger fixed = 0;
	NSArray *objs = [[AppDelegate myApp] allItemsOfType:kAny];

	for (ItemUse *use in objs)
	{
		if ([use.givenName isEqualToString:@"ID"])
		{
			// See if we got a better name
			Person *pers = [[AppDelegate myApp] findOrCreatePersonWithID:[use.personID integerValue]];
			if ([pers.surname length] && ![pers.surname isEqualToString:use.surname])
			{
				use.surname = pers.surname;
				fixed++;
			}
			if ([pers.givenName length] && ![pers.givenName isEqualToString:use.givenName])
			{
				use.givenName = pers.givenName;
				fixed++;
			}
		}
	}
	if (fixed > 0)
	{
		NSLog(@"%lu Person names fixed in ItemUses", (long)fixed);
		[[AppDelegate myApp] saveContext];
	}
	return fixed > 0;
}


- (NSArray *)allObjectsOfEntityName:(NSString *)ename sortedBy:(NSArray *)sortKeys
{
	NSError *err = nil;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:ename inManagedObjectContext:_managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	
	NSMutableArray *sdecs = [NSMutableArray arrayWithCapacity:[sortKeys count]];
	for (NSString *skey in sortKeys) {
		[sdecs addObject:[[NSSortDescriptor alloc] initWithKey:skey ascending:YES]];
	}
	[request setSortDescriptors:sdecs];
	
	NSArray *array = [_managedObjectContext executeFetchRequest:request error:&err];
	if (!array) {
		NSLog(@"error fetching for allObjects %@", [err localizedDescription]);
		return nil;
	}
	return array;
}


- (NSString *)csvFromPersonsAndProducts
{
	NSMutableString *str = [[NSMutableString alloc] initWithString:@"Entity,ID,Modified,Title,Surname,Given Name,Level,Affiliation,Cell Phone\n"];
	NSDateFormatter *dateFmtr = [[NSDateFormatter alloc] init];
	[dateFmtr setDateFormat:kCSVFileDateFormat];
	
	NSArray *objs = [self allObjectsOfEntityName:@"Person" sortedBy:@[@"surname", @"givenName"]];
	for (Person *per in objs)
	{
		NSString *line = [NSString stringWithFormat:@"Person,%@,%@,,%@,%@,%@,%@,%@\n",
						  [per personID],
						  [dateFmtr stringFromDate:[per modified]],
						  [per surname] ? [per surname] : [NSString stringWithFormat:@"Person %@", [per personID]],
						  [per givenName] ? [per givenName] : @"",
						  [per level] ? [per level] : @"",
						  [per affiliation] ? [per affiliation] : @"",
						  [per cellPhone] ? [per cellPhone] : @""];
		[str appendString:line];
	}
	objs = [self allObjectsOfEntityName:@"Product" sortedBy:@[@"title", @"productID"]];
	for (Product *pro in objs)
	{
		NSString *line = [NSString stringWithFormat:@"Product,%@,%@,%@\n",
						  [pro productID],
						  [dateFmtr stringFromDate:[pro modified]],
						  [pro title] ? [pro title] : @"Untitled"];
		[str appendString:line];
	}
	return str;
}


- (void)errorAlertOnError:(NSError *)err
{
	UIAlertController *ctrlr = [UIAlertController alertControllerWithTitle:@"Internal Error" message:[err localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
	[ctrlr addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
	[self presentViewController:ctrlr animated:YES completion:nil];
}


- (void)askUser:(NSString *)question actionTitle:(NSString *)atitle cancelTitle:(NSString *)ctitle
	destructive:(BOOL)isScary onViewController:(UIViewController *)vc inRect:(CGRect)rect
{
	UIAlertController *ctrlr = [UIAlertController alertControllerWithTitle:question message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[ctrlr addAction:[UIAlertAction actionWithTitle:atitle style:isScary ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self performOnAnswer:YES onController:self];
	}]];
	[ctrlr addAction:[UIAlertAction actionWithTitle:ctitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		[self performOnAnswer:NO onController:self];
	}]];
	
	// This is required by runtime (as of SDK 15) for UIAlertControllerStyleActionSheet
	ctrlr.popoverPresentationController.sourceView = self.view;
	ctrlr.popoverPresentationController.sourceRect = rect;

	[vc presentViewController:ctrlr animated:YES completion:nil];
}


#pragma mark - Navigation
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
