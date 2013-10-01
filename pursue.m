#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>

#import <subjc.h>

#import "pursue.h"
#import "Settings.m"

static PursueUpdateManager *sharedPursueUpdateManager;

@implementation PursueUpdateManager

+ (PursueUpdateManager *)sharedInstance
{
	if (!sharedPursueUpdateManager)
		sharedPursueUpdateManager = [[PursueUpdateManager alloc] init];
	return sharedPursueUpdateManager;
}

- (id)init
{
	if ((self = [super init])) {
		_locationManager = [[CLLocationManager alloc] init];
		[_locationManager setDelegate:self];
	}
	return self;
}

- (void)dealloc
{
	[_locationToUpdateTo release];
	[_locationManager stopUpdatingLocation];
	[_locationManager setDelegate:nil];
	[_locationManager release];
	[_connector setDelegate:nil];
	[_connector release];
	[super dealloc];
}

- (void)update
{
	NSLog(@"Pursue: Updating...");
	PrepareSettings();
	if (UpdateEnabled) {
		if (_connector == nil || [_connector isFailed]) {
			[_connector setDelegate:nil];
			[_connector release];
			_connector = [[LatitudeConnector alloc] initWithAccount:LatitudeAccountEmailAddress password:LatitudeAccountPassword delegate:self];
		}
		[_locationToUpdateTo release];
		_locationToUpdateTo = nil;
		[_locationManager startUpdatingLocation];
	}
}

- (void)reloadSettings
{
	[_connector setDelegate:nil];
	[_connector release];
	_connector = nil;
	[self update];
}

- (void)latitudeConnectorDidFailLogin:(LatitudeConnector *)lc
{
	NSLog(@"Pursue: Login Failed for %@; disabling", LatitudeAccountEmailAddress);
	NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@kSettingsFilePath];
	[settings removeObjectForKey:@"LatitudeAccountEmailAddress"];
	[settings writeToFile:@kSettingsFilePath atomically:YES];
	[settings release];
}

- (void)latitudeConnector:(LatitudeConnector *)lc didFailWithError:(NSError *)error
{
	NSLog(@"Pursue: Unknown Error: %@", error);
}

- (void)latitudeConnectorDidUpdateLocation:(LatitudeConnector *)lc
{
	NSLog(@"Pursue: Success!");
}

- (void)latitudeConnectorDidLogin:(LatitudeConnector *)lc
{
	if (_locationToUpdateTo) {
		[_connector updateWithLocation:_locationToUpdateTo];
		[_locationToUpdateTo release];
		_locationToUpdateTo = nil;
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	if ([newLocation horizontalAccuracy] <= kCLLocationAccuracyHundredMeters) {
		if ([_connector isReady])
			[_connector updateWithLocation:newLocation];
		else
			_locationToUpdateTo = [newLocation retain];
		[manager stopUpdatingLocation];
	}
}

@end

CHDeclareClass(MailAppController);

CHMethod1(void, MailAppController, fetchButtonClicked, UIView *, button)
{
	[[PursueUpdateManager sharedInstance] update];	
	CHSuper1(MailAppController, fetchButtonClicked, button);
}

CHDeclareClass(MailboxContentViewController);

CHMethod1(void, MailboxContentViewController, fetchButtonClicked, UIView *, button)
{
	[[PursueUpdateManager sharedInstance] update];
	CHSuper1(MailboxContentViewController, fetchButtonClicked, button);
}

CHDeclareClass(AutoFetchController);

CHMethod0(void, AutoFetchController, handlePollEvent)
{
	[[PursueUpdateManager sharedInstance] update];	
	CHSuper0(AutoFetchController, handlePollEvent);
}

CHMethod0(void, AutoFetchController, startup)
{
	CHSuper0(AutoFetchController, startup);
	[self startAutoFetch];
	[[PursueUpdateManager sharedInstance] update];	
}

CHConstructor
{
	CHAutoreleasePoolForScope();
	
	[[NSNotificationCenter defaultCenter] addObserver:[PursueUpdateManager sharedInstance] selector:@selector(update) name:@"com.apple.mobilemail.autofetch" object:nil];
	SetSettingsChangedDelegate([PursueUpdateManager sharedInstance], @selector(reloadSettings));
	
	CHLoadLateClass(MailAppController);
	CHHook1(MailAppController, fetchButtonClicked);
	
	CHLoadLateClass(MailboxContentViewController);
	CHHook1(MailboxContentViewController, fetchButtonClicked);
		
	CHLoadLateClass(AutoFetchController);
	CHHook0(AutoFetchController, startup);
	CHHook0(AutoFetchController, handlePollEvent);
}