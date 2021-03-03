//
//  ScanViewController.m
//  LogScan
//
//  Created by Paul A Collins on 4/25/15.
//  Copyright (c) 2015–2021 Gracion Software and Paul A. Collins. All rights reserved.
//  This source code is distributed under the terms of the GNU General Public License
//

#import "ScanViewController.h"

#import "AppDelegate.h"
#import "EntityEditViewController.h"
#import "HelpViewController.h"
#import "LogsViewController.h"
#import "ItemUse+CoreDataProperties.h"
#import "Person+CoreDataProperties.h"
#import "Product+CoreDataProperties.h"
#import <AVFoundation/AVFoundation.h>

// Camera box overlay drawing
CGMutablePathRef createPathForPoints(NSArray* points) {
	CGMutablePathRef path = CGPathCreateMutable();
	CGPoint point;
	if ([points count] > 0) {
		CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[points objectAtIndex:0], &point);
		CGPathMoveToPoint(path, nil, point.x, point.y);
		int i = 1;
		while (i < [points count]) {
			CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[points objectAtIndex:i], &point);
			CGPathAddLineToPoint(path, nil, point.x, point.y);
			i++;
		}
		CGPathCloseSubpath(path);
	}
	return path;
}


@interface ScanViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CALayer *targetLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) NSMutableArray *codeObjects;

@property (nonatomic, weak) NSTimer *hideTargetTimer;
@property (nonatomic, weak) NSTimer *tooFastScanTimer;

@property (nonatomic, strong) Product *currentLocation;

@end

@implementation ScanViewController
{
	BOOL _hadHyphen;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.synth = [[AVSpeechSynthesizer alloc] init];
	[self clearAction:nil];
	self.resultText.text = @"";
	self.codeObjects = [NSMutableArray arrayWithCapacity:9];
}


- (void)viewDidAppear:(BOOL)animated
{
	// run the reader when the view is visible
	[self startRunning];
	self.resultText.text = @"(ready)";

	//[self.scanTextField becomeFirstResponder];
}

- (void) viewWillDisappear: (BOOL) animated
{
	[self stopRunning];
}


- (void)dealloc {
	[_hideTargetTimer invalidate];
}


- (Product *)locationProduct
{
	if (!_currentLocation)
	{
		// Use the single "location"
		_currentLocation = [[AppDelegate myApp] locationWithID: -1];
	}
	
	return _currentLocation;
}


#pragma mark - AVCapture

// configure our scanner capture session with preview
- (AVCaptureSession *)captureSession {
	if (!_captureSession) {
		NSError *error = nil;
		// Faster focus
		AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		if (device.isAutoFocusRangeRestrictionSupported) {
			if ([device lockForConfiguration:&error]) {
				[device setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNear];
				[device unlockForConfiguration];
			}
		}
		AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput
											 deviceInputWithDevice:device error:&error];
		if (deviceInput) {
			_captureSession = [[AVCaptureSession alloc] init];
			if ([_captureSession canAddInput:deviceInput]) {
				[_captureSession addInput:deviceInput];
			}
		}
		AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
		if ([_captureSession canAddOutput:metadataOutput]) {
			[_captureSession addOutput:metadataOutput];
			[metadataOutput setMetadataObjectsDelegate:self
												 queue:dispatch_get_main_queue()];
			// If you want to support all possible types, you could use this array, but be warned
			// it includes "face" and perhaps others that aren't barcodes
			// NSLog(@"aval types: %@", [scanOutput availableMetadataObjectTypes]);
			
			[metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code]];
		}
		self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
		self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
		self.previewLayer.frame = self.readerView.bounds;
		// possibly this wants to be the self.view.layer but I doubt it
		[self.readerView.layer addSublayer:self.previewLayer];
		
		self.targetLayer = [CALayer layer];
		self.targetLayer.frame = self.readerView.bounds;
		[self.readerView.layer addSublayer:self.targetLayer];
	}
	return _captureSession;
}


- (void)startRunning {
  [self.captureSession startRunning];
}


- (void)stopRunning {
  [self.captureSession stopRunning];
  self.captureSession = nil;
}


// TODO add background/foreground stop/start (real use case?)

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
       didOutputMetadataObjects:(NSArray *)metadataObjects
	   fromConnection:(AVCaptureConnection *)connection {
	[self.codeObjects removeAllObjects];
	for (AVMetadataObject *metadataObject in metadataObjects) {
		AVMetadataObject *transformedObject = [self.previewLayer
											   transformedMetadataObjectForMetadataObject:metadataObject];
		[self.codeObjects addObject:transformedObject];
		
		if ([metadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
		{
			AVMetadataMachineReadableCodeObject *codeObject = (AVMetadataMachineReadableCodeObject *)metadataObject;
			NSString *code = codeObject.stringValue;
			if (code && ![code isEqualToString:self.lastScanData])
			{
				// If two or more barcodes are in view, AVCapture rapidly repeats them. Bypass.
				// (If you don't, speech-to-text will talk for the next couple of minutes)
				// But do allow if previous scan was the other type by checking for hyphen
				BOOL tooFast = NO;
				BOOL hasHyphen = [code rangeOfString:@"-"].location != NSNotFound;
				if (hasHyphen == _hadHyphen && self.tooFastScanTimer)
				{
					[self.tooFastScanTimer invalidate];
					tooFast = YES;
				}
				_hadHyphen = hasHyphen;
				
				__weak ScanViewController *weakSelf = self;
				self.tooFastScanTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:NO block:^(NSTimer * _Nonnull timer)
				{
					weakSelf.tooFastScanTimer = nil;
				}];
				
				if (tooFast)
				{
					return;
				}


				self.resultText.text = code;
				[self scanIn:code];
				self.lastScanData = code; // this has to be after scanIn is called.
			}
			[self clearTargetLayer];
			[self showDetectedObjects];
		}
	}
}


#pragma mark - capture support

- (void)clearTargetLayer {
	NSArray *sublayers = [[self.targetLayer sublayers] copy];
	for (CALayer *sublayer in sublayers) {
		[sublayer removeFromSuperlayer];
	}
}


- (void)showDetectedObjects {
	for (AVMetadataObject *object in self.codeObjects) {
		if ([object isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
			CAShapeLayer *shapeLayer = [CAShapeLayer layer];
			shapeLayer.strokeColor = [UIColor redColor].CGColor;
			shapeLayer.fillColor = [UIColor clearColor].CGColor;
			shapeLayer.lineWidth = 2.0;
			shapeLayer.lineJoin = kCALineJoinRound;
			CGPathRef path = createPathForPoints([(AVMetadataMachineReadableCodeObject *)object corners]);
			shapeLayer.path = path;
			CFRelease(path);
			[self.targetLayer addSublayer:shapeLayer];
		}
	}
	// show for up to a second after last successful scan
	[_hideTargetTimer invalidate];
	__weak ScanViewController *weakSelf = self;
	self.hideTargetTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[weakSelf clearTargetLayer];
		weakSelf.hideTargetTimer = nil;
	}];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    // seque identifier may be "entityEdit" or "signPersonEdit" but we're going to a single type
    // of controller:
	if ([[segue destinationViewController] isKindOfClass:[EntityEditViewController class]]) {
		
		NSManagedObject * obj = nil;
		if ([sender isKindOfClass:[NSManagedObject class]])
			obj = sender;
		else
			obj = self.personObj;
		
		[(EntityEditViewController *)[segue destinationViewController] acceptObjectToEdit:obj];
	}
	else if ([[segue destinationViewController] isKindOfClass:[HelpViewController class]])
	{
		NSURL *url = [[NSBundle mainBundle] resourceURL];
		url = [url URLByAppendingPathComponent:(self.myMaster.useType == kSignIn) ?
			   @"help_signin.txt" : @"help_inventory.txt"];
		NSString *help = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
		[(HelpViewController *)[segue destinationViewController] setHelpText:help];
	}
}


- (IBAction)clearAction:(id)sender {
	self.wasLogged = NO;
	//wentOut is invalid
	self.personID = 0;
	self.itemTypeID = 0;
	self.surname = nil;
	self.givenName = nil;
	self.lastScanResult = ScanUnknown;
	self.lastScanData = nil;
	self.personObj = nil;
	if (self.myMaster.useType == kSignIn)
	{
		self.productObj = [self locationProduct];
		self.itemNumber = -1;	// future? [self.productObj.productID integerValue]
	}
	else
	{
		self.productObj = nil;
		self.itemNumber = 0;
	}
	
	[self refresh];
	self.resultText.text = @"";
}


- (IBAction)closeAction:(id)sender {
	[self.myMaster.parentViewController dismissViewControllerAnimated:YES completion:NULL];
}


// Shortcut to log a team by number instead of a person
- (IBAction)teamButtonAction:(id)sender {
	NSUInteger num = [sender tag];
	if (num < 1)
		return; // ignore
	
	if (self.wasLogged)
		[self clearAction:nil];
	
	// Use the tag as the team number and person ID. Include something for given name to avoid edit mode.
	//TODO: Could conflict if same ID is assigned elsewhere.
	NSString *fakeScanText = [NSString stringWithFormat:@"Team %lu.*/%lu", (unsigned long)num,(unsigned long)num];
	if ([fakeScanText isEqualToString:self.lastScanData])
		return; // double-tap
	
	ScanResult result = [self parseScanText:fakeScanText];
	if (result == ScanResultDeferred)
		return; // Shouldn't happen
	
	self.lastScanResult = result;
	[self processResult:result];

	self.lastScanData = fakeScanText;
}

- (void)scanIn:(NSString *)input {

	// after logging an event, next scan starts new record
	if (self.wasLogged)
		[self clearAction:nil];
	
	ScanResult result = [self parseScanText:input];
	if (result == ScanResultDeferred)
		return;
	
	self.lastScanResult = result;
	[self processResult:result];
}


// Requires that result object is in self.personObj or self.productObj

- (void)processResult:(ScanResult)result {
	
	BOOL readyToCheckout = NO;
	
	switch (result) {
		case ScannedPersonID:
		case ScannedPerson:
		{
			if (self.personObj)
			{
				if (self.myMaster.useType == kSignIn)
				{
					ItemUse *itemUse = [self itemUseForSignedInPerson];
					if (itemUse)
					{
						// Person is signed in - sign them out
						[self signOutPersonWithItemUse:itemUse];
					}
					else
					{
						readyToCheckout = YES; // ready to sign in
					}
				}
				else
				{
					if (self.itemNumber)
						readyToCheckout = YES;
					else
						[self say:self.surname];
				}
			}
			else
			{
				NSLog(@"Unexpectedly failed to create Person %ld", (long)self.personID);
			}

			break;
		}
		case ScannedItem:
			if (self.myMaster.useType == kSignIn)
			{
				[self say:@"This is sign in. To scan items, use logistics."];
				return;
			}
			if (self.productObj)
			{
				if (self.personObj)
				{
					readyToCheckout = YES;
				}
				else
				{
					// item scan only. may be checkin
					if ([self isItemOut:self.itemTypeID num:self.itemNumber])
					{
						// TODO: confirm if < 1 minute since checkout
						[self checkInNowAndUpdate:YES];
					}
					else
					{
						// otherwise it's just noted and we wait for person scan to check out
						[self say:[NSString stringWithFormat:@"%@ %ld", [self.productObj title], (long)self.itemNumber]];
					}
				}
			}
			else
			{
				NSLog(@"Unexpectedly failed to create Product %ld", (long)self.itemTypeID);
			}
			
			break;
		default:
			break;
	}
	
	if (readyToCheckout)
	{
		NSManagedObject *obj = nil;
		if (self.myMaster.useType == kInventory && (obj = [self isItemOut:self.itemTypeID num:self.itemNumber]))
		{
			[self askIfReOutAsync:obj]; // callback from sheet determines action
		}
		else
		{
			[self.myMaster acceptScanObject:self];
			self.wentOut = YES;
			self.wasLogged = YES;
			if (self.myMaster.useType == kSignIn)
			{
				[self say:[NSString stringWithFormat:@"Signed in %@", self.surname]];
			}
			else
			{
				[self say:[NSString stringWithFormat:@"Checked out %@ %ld to %@", [self.productObj title], (long)self.itemNumber, self.surname]];
			}
		}
	}
	[[AppDelegate myApp] setNeedsSave];
	[self refresh];
}


// scan ItemUse list to see if an item is currently checked out

- (NSManagedObject *)isItemOut:(NSInteger)itemTypeID num:(NSInteger)num
{
	NSError *err = nil;
	NSManagedObjectContext *moc = self.myMaster.managedObjectContext;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ItemUse" inManagedObjectContext:moc];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];

	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(itemNumber = %@) AND (itemTypeID = %@) AND (isOut = YES)", @(num), @(itemTypeID)];
	[request setPredicate:pred];
	
	NSArray *array = [moc executeFetchRequest:request error:&err];
	if (!array) {
		NSLog(@"error fetching for isItemOut %@", [err localizedDescription]);
		return nil;
	}
	if ([array count] > 0)
	{
		return array[0];
	}
	return nil;
}


- (ItemUse *)itemUseForSignedInPerson
{
	NSError *err = nil;
	NSManagedObjectContext *moc = self.myMaster.managedObjectContext;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ItemUse" inManagedObjectContext:moc];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];

	NSPredicate *pred = [NSPredicate predicateWithFormat:@"(personID = %@) AND (useType = %@) AND (isOut = YES)", @(self.personID), @(kSignIn)];
	[request setPredicate:pred];

	NSArray *array = [moc executeFetchRequest:request error:&err];
	return [array firstObject]; // nil if nothing found
}


- (void)askIfReOutAsync:(NSManagedObject *)obj
{
	NSString *title = [NSString stringWithFormat:@"%@-%@ is checked out to %@, %@.", [obj valueForKey:@"itemTypeID"], [obj valueForKey:@"itemNumber"], [obj valueForKey:@"surname"], [obj valueForKey:@"givenName"]];
	UIAlertController *ctrlr = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	
	[ctrlr addAction:[UIAlertAction actionWithTitle:@"Check Out" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			// check out by first checking in
			[self checkInNowAndUpdate:NO];
			[self.myMaster acceptScanObject:self];
			self.wentOut = YES;
			self.wasLogged = YES;
			[self say:[NSString stringWithFormat:@"Re-checked out %@ %ld to %@", [self.productObj title], (long)self.itemNumber, self.surname]];
	}]];
	[ctrlr addAction:[UIAlertAction actionWithTitle:@"Check In Only" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[self checkInNowAndUpdate:YES];
	}]];
		[ctrlr addAction:[UIAlertAction actionWithTitle:@"Ignore Scan" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		[self ignoreLastScan];
	}]];

	[self presentViewController:ctrlr animated:YES completion:nil];
}


// Sign-in item/record is itemUse
// person scanned is self.personObj
- (void)signOutPersonWithItemUse:(ItemUse *)itemUse
{
	itemUse.isOut = @(NO);
	itemUse.inTime = [NSDate date]; // time signed out
	
	self.wasLogged = YES;
	self.wentOut = NO;
	// person info (personId, givenname, surname) already assigned to self
	
	[self say: [NSString stringWithFormat:@"Signed out %@", self.surname]];
	
	// If update issues are seen, do direct save here which item login does
	
	[self.myMaster notifySignIn:itemUse isIn:NO];
}


- (void)ignoreLastScan
{
	// last scan could be person or thing
	switch (self.lastScanResult) {
		case ScannedItem:
			self.itemNumber = 0;
			self.itemTypeID = 0;
			self.wasLogged = NO;
			break;
		case ScannedPerson:
		case ScannedPersonID:
			self.personID = 0;
			self.surname = nil;
			self.givenName = nil;
		default:
			break;
	}
	self.lastScanResult = ScanUnknown;
	[self refresh];
}

// requires an item be in my props
- (BOOL)checkInNowAndUpdate:(BOOL)doUpdate
{
	NSError *err = nil;
	NSManagedObject *obj = [self.myMaster acceptScanIn:self error:&err];
	if (obj && doUpdate)
	{
		self.wasLogged = YES;
		self.wentOut = NO;
		self.personID = [[obj valueForKey:@"personID"] integerValue];
		self.givenName = [obj valueForKey:@"givenName"];
		self.surname = [obj valueForKey:@"surname"];
		[self say:[NSString stringWithFormat:@"Checked in %@ %ld from %@", [self.productObj title], (long)self.itemNumber, self.surname]];
	}
	if (!obj)
	{
		UIAlertController *ctrlr = [UIAlertController alertControllerWithTitle:@"Can't check in" message:[err localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
		[ctrlr addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:ctrlr animated:YES completion:nil];
		return NO;
	}
	[self refresh];
	return YES;
}


- (void)refresh
{
	if (self.surname)
	{
		self.nameLabel.text = [NSString stringWithFormat:@"%@, %@", self.surname, self.givenName ? self.givenName : @""];
	}
	else
		self.nameLabel.text = @"";
	
	if (self.personID > 0) {
		self.personIDLabel.text = [@(self.personID) stringValue];
		self.editButton.enabled = YES;
	}
	else
	{
		self.personIDLabel.text = @"";
		self.editButton.enabled = NO;
	}
	
	if (self.itemNumber > 0)
	{
		self.itemNumberLabel.text = [@(self.itemNumber) stringValue];
		self.itemNameLabel.text = [self.productObj title];
	}
	else
	{
		self.itemNumberLabel.text = @"";
		self.itemNameLabel.text = @"";
	}
	if (self.wasLogged)
	{
		if (self.myMaster.useType == kSignIn)
				self.inOutView.image = [UIImage imageNamed:(self.wentOut ? @"signedIn" : @"signedOut")];
		else
			self.inOutView.image = [UIImage imageNamed:(self.wentOut ? @"out" : @"back")];
		}
	else
	{
		self.inOutView.image = nil;
	}
}


- (ScanResult)parseScanText:(NSString *)raw
{
	ScanResult result = ScanUnknown;
	if ([raw rangeOfString:@"/"].location != NSNotFound)
	{
		// Named person
		NSArray *parts = [raw componentsSeparatedByString:@"/"];
		NSArray *nameParts = [parts[0] componentsSeparatedByString:@"."];
		self.surname = nameParts[0];
		if ([nameParts count] > 1)
			self.givenName = nameParts[1];
		else
			self.givenName = @"";
		
		self.personID = [parts[1] integerValue];
		self.personObj = [[AppDelegate myApp] findOrCreatePersonWithID:self.personID];
		
		// When a person barcode includes the name, put it into the person object
		if ([self.surname length])
		{
			if ([self.surname length] &&![self.surname isEqualToString:self.personObj.surname])
			{
				self.personObj.surname = self.surname;
			}
		}
		else
		{
			self.surname = [self.personObj.surname length] ? self.personObj.surname : nil;
		}
		if ([self.givenName length])
		{
			if (![self.givenName isEqualToString:self.personObj.givenName])
			{
				self.personObj.givenName = self.givenName;
			}
		}
		else
		{
			self.givenName = [self.personObj.givenName length] ? self.personObj.givenName : nil;
		}
		if (!self.givenName)
		{
			if (self.myMaster.useType == kSignIn)
			{
				[self performSegueWithIdentifier:@"signPersonEdit" sender:self.personObj];
			}
				else
			{
				[self performSegueWithIdentifier:@"entityEdit" sender:self.personObj];
			}
			return ScanResultDeferred;
		}
		result = ScannedPerson;
	}
	else if ([raw rangeOfString:@"-"].location != NSNotFound)
	{
		//item
		NSArray *parts = [raw componentsSeparatedByString:@"-"];
		self.itemTypeID = [parts[0] integerValue];
		self.itemNumber = [parts[1] integerValue];
		
		self.productObj = [[AppDelegate myApp] findOrCreateProductWithID:self.itemTypeID];
		if (!self.productObj.title)
		{
			self.productObj.title = [NSString stringWithFormat:@"Item ID %ld", (long)self.itemTypeID];
		}
		result = ScannedItem;
	}
	else
	{
		// just a number, assume CERT person id  (display name will be looked up on demand?)
		self.personID = [raw integerValue];
		self.personIDLabel.text = [@(self.personID) stringValue];

		Person *pers = [[AppDelegate myApp] findOrCreatePersonWithID:self.personID];
		self.personObj = pers;
		if ([pers.surname length] > 0) {
			self.surname = pers.surname;
			self.givenName = pers.givenName;
		} else {
			self.surname = nil;
			self.givenName = nil;
			if (self.myMaster.useType == kSignIn)
			{
				[self performSegueWithIdentifier:@"signPersonEdit" sender:pers];
			}
				else
			{
				[self performSegueWithIdentifier:@"entityEdit" sender:pers];
			}
			return ScanResultDeferred;
		}
		result = ScannedPersonID;
	}
	return result;
}


#pragma mark - speech

- (void)say:(NSString *)str
{
	NSString *vocal = [str stringByReplacingOccurrencesOfString:@"RAGEN" withString:@"REAGAN"];
	AVSpeechUtterance *ut = [AVSpeechUtterance speechUtteranceWithString:vocal];
	[self.synth speakUtterance:ut];
}

#pragma mark - unwind

- (IBAction)cancelUnwindAction:(UIStoryboardSegue*)unwindSegue
{
}


// TEMP - just Person
- (IBAction)saveUnwindAction:(UIStoryboardSegue*)unwindSegue
{
	EntityEditViewController *editVC = [unwindSegue sourceViewController];
	NSManagedObject *obj = editVC.editObj;
	// Get the surname or put in ID-based name
	NSString *name = [editVC.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([name length] == 0 )
		name = [NSString stringWithFormat:@"Person %lu", (long)[obj valueForKey:@"personID"]];
	self.surname = name;
	// Given name may be blank
	self.givenName = [editVC.givenNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[obj setValue:name forKey:@"surname"];
	[obj setValue:self.givenName forKey:@"givenName"];
	
	[[AppDelegate myApp] saveContext];
	
	self.lastScanResult = ScannedPerson;
	[self processResult:ScannedPerson];
}


@end
