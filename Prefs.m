#import <Foundation/Foundation.h>
#import <Preferences/Preferences.h>

#import "LatitudeConnector.m"
#import "Settings.m"

@interface PursueSettingsController : PSListController<LatitudeConnectorDelegate> {
@private
	LatitudeConnector *_latitudeConnector;
}
@end

@implementation PursueSettingsController

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[av show];
	[av release];
}

- (void)latitudeConnector:(LatitudeConnector *)lc didFailWithError:(NSError *)error
{
	[self showAlertWithTitle:@"Unknown Error" message:[error localizedDescription]];
}

- (void)latitudeConnectorDidLogin:(LatitudeConnector *)lc
{
	[self showAlertWithTitle:@"Login successful" message:nil];
}

- (void)latitudeConnectorDidFailLogin:(LatitudeConnector *)lc
{
	[self showAlertWithTitle:@"Invalid Login Details" message:@"Ensure your email address and password are correct and try again"];
}

- (NSArray *)loadSpecifiersFromPlistName:(NSString *)plistName target:(id)target
{
	return [super loadSpecifiersFromPlistName:plistName target:self];
}

- (void)testLogin:(PSSpecifier *)specifier
{
	PrepareSettings();
	[_latitudeConnector setDelegate:nil];
	[_latitudeConnector release];
	_latitudeConnector = [[LatitudeConnector alloc] initWithAccount:LatitudeAccountEmailAddress password:LatitudeAccountPassword delegate:self];
}

- (void)upgradeToFindMyI:(PSSpecifier *)specifier
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"http://booleanmagic.com/services/findmyiupgrade/?device=" stringByAppendingString:[[UIDevice currentDevice] uniqueIdentifier]]]];
}

- (void)dealloc
{
	[_latitudeConnector setDelegate:nil];
	[_latitudeConnector release];
	[super dealloc];
}

@end