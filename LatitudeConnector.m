//
//  LatitudeConnector.m
//  LatitudeUpdater
//
//  Created by Ryan Petrich on 28/10/09.
//  Copyright 2009 Ryan Petrich. All rights reserved.
//

#import "LatitudeConnector.h"

#define kStateFailed				-1
#define kStateObtainingCookies		0
#define kStateObtainingLoginForm	1
#define kStateLoggingIn				2
#define kStateReady					3
#define kStateUpdatingLocation		4

#define kObtainCookiesURL		@"http://maps.google.com/maps/m?mode=latitude"
#define kObtainLoginFormURL		@"https://www.google.com/accounts/ServiceLogin?service=friendview&hl=en&nui=1&continue=http://maps.google.com/maps/m%3Fmode%3Dlatitude"
#define kLoggingInURL			@"https://www.google.com/accounts/ServiceLoginAuth?service=friendview"
#define kUpdateLocationURL		@"http://maps.google.com/glm/mmap/mwmfr?hl=en"


@implementation LatitudeConnector

@synthesize delegate = _delegate;

+ (NSMutableURLRequest *)requestWithURL:(NSString *)url referer:(NSString *)referer
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request addValue:@"Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_1_2 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7D11 Safari/528.16" forHTTPHeaderField:@"User-Agent"];
	if (referer)
		[request addValue:referer forHTTPHeaderField:@"Referer"];
	[request setHTTPShouldHandleCookies:YES];
	return request;
}

+ (NSString *)extractFieldWithName:(NSString *)fieldName fromFormString:(NSString *)formString
{
	NSRange rangeOfField = [formString rangeOfString:[fieldName stringByAppendingString:@"=\""]];
	if (rangeOfField.location == NSNotFound) {
		rangeOfField = [formString rangeOfString:[fieldName stringByAppendingString:@"=\'"]];
		if (rangeOfField.location == NSNotFound)
			return nil;
	}
	NSRange rangeToSearch;
	rangeToSearch.location = rangeOfField.location + rangeOfField.length;
	rangeToSearch.length = [formString length] - rangeToSearch.location;
	NSRange rangeOfClosingQuote = [formString rangeOfString:@"\"" options:NSLiteralSearch range:rangeToSearch];
	if (rangeOfClosingQuote.location == NSNotFound) {
		rangeOfClosingQuote = [formString rangeOfString:@"\'" options:NSLiteralSearch range:rangeToSearch];
		if (rangeOfClosingQuote.location = NSNotFound)
			return [formString substringFromIndex:rangeOfField.location + rangeOfField.length];
	}
	return [formString substringWithRange:NSMakeRange(rangeToSearch.location, rangeOfClosingQuote.location - rangeToSearch.location)];
}

- (id)initWithAccount:(NSString *)account password:(NSString *)password delegate:(id<LatitudeConnectorDelegate>)delegate
{
	if ((self = [super init])) {
		_account = [account copy];
		_password = [password copy];
		_delegate = delegate;
		_data = [[NSMutableData alloc] init];
		_currentConnection = [[NSURLConnection alloc] initWithRequest:[LatitudeConnector requestWithURL:kObtainCookiesURL referer:nil] delegate:self startImmediately:YES];
	}
	return self;
}

- (void)dealloc
{
	[_currentConnection cancel];
	[_currentConnection release];
	[_data release];
	[_password release];
	[_account release];
	[_lastURL release];
	[super dealloc];
}

- (void)_failWithErrorCode:(NSUInteger)errorCode description:(NSString *)description
{
	_state = kStateFailed;
	[_currentConnection cancel];
	[_currentConnection release];
	_currentConnection = nil;
	[_data setLength:0];
	if ([_delegate respondsToSelector:@selector(latitudeConnector:didFailWithError:)]) {
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
		[errorDetail setValue:description forKey:NSLocalizedDescriptionKey];
		[_delegate latitudeConnector:self didFailWithError:[NSError errorWithDomain:@"com.booleanmagic.latitudeconnector" code:errorCode userInfo:errorDetail]];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	_state = kStateFailed;
	[_currentConnection release];
	[_data setLength:0];
	if ([_delegate respondsToSelector:@selector(latitudeConnector:didFailWithError:)])
		[_delegate latitudeConnector:self didFailWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[_data setLength:0];
	[_lastURL release];
	_lastURL = [[[response URL] absoluteString] retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (_data) {
		NSString *document = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
		NSLog(@"Pursue Response: %@", document);
		[document release];
	}
	[_currentConnection release];
	_currentConnection = nil;
	switch (_state) {
		case kStateObtainingCookies: {
			_state = kStateObtainingLoginForm;
			_currentConnection = [[NSURLConnection alloc] initWithRequest:[LatitudeConnector requestWithURL:kObtainLoginFormURL referer:_lastURL] delegate:self startImmediately:YES];
			break;
		}
		case kStateObtainingLoginForm: {
			NSString *document = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
			NSMutableString *postData = [NSMutableString string];
			for (NSString *part in [document componentsSeparatedByString:@"type=\"hidden\""]) {
				NSString *name = [LatitudeConnector extractFieldWithName:@"name" fromFormString:part];
				if (name) {
					NSString *value = [LatitudeConnector extractFieldWithName:@"value" fromFormString:part];
					if (value)
						[postData appendFormat:@"%@=%@&", name, [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				}
			}
			[document release];
			[postData appendString:@"signIn=Sign+in&PersistentCookie=yes&Email="];
			[postData appendString:[_account stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			[postData appendString:@"&Passwd="];
			[postData appendString:[_password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			NSMutableURLRequest *request = [LatitudeConnector requestWithURL:kLoggingInURL referer:_lastURL];
			[request setHTTPMethod:@"POST"];
			[request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
			_state = kStateLoggingIn;
			_currentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
			break;
		}
		case kStateLoggingIn: {
			NSString *document = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
			if ([document rangeOfString:@"refresh"].location != NSNotFound) {
				_state = kStateReady;
				if ([_delegate respondsToSelector:@selector(latitudeConnectorDidLogin:)])
					[_delegate latitudeConnectorDidLogin:self];
			} else {
				_state = kStateFailed;
				if ([_delegate respondsToSelector:@selector(latitudeConnectorDidFailLogin:)])
					[_delegate latitudeConnectorDidFailLogin:self];
				else
					[self _failWithErrorCode:100 description:@"Login Failed!"];
			}
			[document release];
			break;
		}
		case kStateUpdatingLocation: {
			_state = kStateReady;
			if ([_delegate respondsToSelector:@selector(latitudeConnectorDidUpdateLocation:)])
				[_delegate latitudeConnectorDidUpdateLocation:self];
			break;
		}
		default: {
			_state = kStateFailed;
			break;
		}
	}
}

- (BOOL)isReady
{
	return _state == kStateReady;
}

- (BOOL)isFailed
{
	return _state == kStateFailed;
}

- (void)updateWithLocation:(CLLocation *)location
{
	if (_state != kStateReady)
		[self _failWithErrorCode:100 description:@"Latitude connector is not ready to send location"];
	else {
		_state = kStateUpdatingLocation;
		CLLocationCoordinate2D coordinate = [location coordinate];
		NSString *postData = [NSString stringWithFormat:@"t=ul&mwmct=iphone&mwmcv=5.8&mwmdt=iphone&mwmdv=30102&auto=true&nr=180000&cts=%.0f&lat=%f&lng=%f&accuracy=%f", 1000 * [[NSDate date] timeIntervalSince1970], coordinate.latitude, coordinate.longitude, [location horizontalAccuracy]];
		NSMutableURLRequest *request = [LatitudeConnector requestWithURL:kUpdateLocationURL referer:_lastURL];
		[request addValue:@"true" forHTTPHeaderField:@"X-ManualHeader"];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
		_currentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];		
	}
}


@end
