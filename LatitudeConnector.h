//
//  LatitudeConnector.h
//  LatitudeUpdater
//
//  Created by Ryan Petrich on 28/10/09.
//  Copyright 2009 Ryan Petrich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@protocol LatitudeConnectorDelegate;

@interface LatitudeConnector : NSObject {
@private
	id<LatitudeConnectorDelegate> _delegate;
	NSURLConnection *_currentConnection;
	NSString *_account;
	NSString *_password;
	NSInteger _state;
	NSMutableData *_data;
	NSString *_lastURL;
}

- (id)initWithAccount:(NSString *)account password:(NSString *)password delegate:(id<LatitudeConnectorDelegate>)delegate;

@property (nonatomic, assign) id<LatitudeConnectorDelegate> delegate;
@property (nonatomic, readonly, getter=isReady) BOOL ready;
@property (nonatomic, readonly, getter=isFailed) BOOL failed;

- (void)updateWithLocation:(CLLocation *)location;

@end

@protocol LatitudeConnectorDelegate<NSObject>
@optional
- (void)latitudeConnector:(LatitudeConnector *)lc didFailWithError:(NSError *)error;
- (void)latitudeConnectorDidLogin:(LatitudeConnector *)lc;
- (void)latitudeConnectorDidFailLogin:(LatitudeConnector *)lc;
- (void)latitudeConnectorDidUpdateLocation:(LatitudeConnector *)lc;
@end
