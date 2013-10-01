#define kSettingsChangeNotification "com.booleanmagic.pursue.settingschange"
#define kSettingsBundlePath "/Library/Pursue"
#define kSettingsFilePath "/User/Library/Preferences/com.booleanmagic.pursue.plist"

static BOOL UpdateEnabled;
static NSString *LatitudeAccountEmailAddress;
static NSString *LatitudeAccountPassword;

static void PrepareSettings();

static id SettingsTarget;
static SEL SettingsSelector;
#define SetSettingsChangedDelegate(target, message) do { \
	SettingsTarget = [target retain]; \
	SettingsSelector = message; \
} while(0)
