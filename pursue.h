#import "LatitudeConnector.m"
#import <CoreLocation/CoreLocation.h>

@interface PursueUpdateManager : NSObject<LatitudeConnectorDelegate, CLLocationManagerDelegate> {
@private
	LatitudeConnector *_connector;
	CLLocationManager *_locationManager;
	CLLocation *_locationToUpdateTo;
}

+ (PursueUpdateManager *)sharedInstance;

- (void)update;
- (void)reloadSettings;

@end
