#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <CaptainHook/CaptainHook.h>
#import "pursue.h"
#import "Settings.h"

static BOOL SettingsPrepared;

static void PrepareSettings()
{
	if (!SettingsPrepared) {
		SettingsPrepared = YES;
		NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:@kSettingsFilePath];
		[LatitudeAccountEmailAddress release];
		LatitudeAccountEmailAddress = [[settings objectForKey:@"LatitudeAccountEmailAddress"] retain];
		[LatitudeAccountPassword release];
		LatitudeAccountPassword = [[settings objectForKey:@"LatitudeAccountPassword"] retain];
		if ([LatitudeAccountEmailAddress length] != 0 && [LatitudeAccountPassword length] != 0) {
			id temp = [settings objectForKey:@"UpdateEnabled"];
			if (temp)
				UpdateEnabled = [temp boolValue];
			else
				UpdateEnabled = YES;
		} else {
			UpdateEnabled = NO;
		}
		[settings release];		
	}
}

static void PreferencesCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	SettingsPrepared = NO;
	[SettingsTarget performSelector:SettingsSelector withObject:nil];
}

CHConstructor
{
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(), //center
		NULL, // observer
		PreferencesCallback, // callback
		CFSTR(kSettingsChangeNotification), // name
		NULL, // object
		CFNotificationSuspensionBehaviorCoalesce
	); 	
}