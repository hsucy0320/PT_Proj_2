//
//  DirectionsExample.m
//  IOSBoilerplate
//
//  Copyright (c) 2011 Alberto Gimeno Brieba
//  
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//  
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//  

#import "DirectionsMap.h"

@implementation DirectionsMap

@synthesize routeLine;
@synthesize source;
@synthesize destination;
@synthesize map;
@synthesize locmanager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
		MKPinAnnotationView* pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
		pin.canShowCallout = YES;
		if (annotation == source) {
			pin.pinColor = MKPinAnnotationColorGreen;
		} else {
			pin.pinColor = MKPinAnnotationColorRed;
		}
		return [pin autorelease];
	}
	return nil;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay {
    if (self.routeLine) {
        MKPolylineView* routeLineView = [[[MKPolylineView alloc] initWithPolyline:self.routeLine] autorelease];
        routeLineView.fillColor = [UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:0.5f];
        routeLineView.strokeColor = [UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:0.5f];
        routeLineView.lineWidth = 8.0f;
        return routeLineView;
    }
	return nil;
}

#pragma mark -
#pragma mark - Directions

- (void) setRoutePoints:(NSArray*)locations {
    // create a c array of points.
	MKMapPoint* pointArr = malloc(sizeof(MKMapPoint) * locations.count);
    
	NSUInteger i, count = [locations count];
	for (i = 0; i < count; i++) {
        // break the string down even further to latitude and longitude fields.
		CLLocation* obj = [locations objectAtIndex:i];
		MKMapPoint point = MKMapPointForCoordinate(obj.coordinate);
		pointArr[i] = point;
	}
	
	if (routeLine) {
		[map removeOverlay:routeLine];
	}
	// create the polyline based on the array of points.
	self.routeLine = [MKPolyline polylineWithPoints:pointArr count:locations.count];
    // clear the memory allocated earlier for the points
	free(pointArr);
	
	[map addOverlay:routeLine];
	
	CLLocationDegrees maxLat = -90.0f;
	CLLocationDegrees maxLon = -180.0f;
	CLLocationDegrees minLat = 90.0f;
	CLLocationDegrees minLon = 180.0f;
	
	for (int i = 0; i < locations.count; i++) {
		CLLocation *currentLocation = [locations objectAtIndex:i];
		if(currentLocation.coordinate.latitude > maxLat) {
			maxLat = currentLocation.coordinate.latitude;
		}
		if(currentLocation.coordinate.latitude < minLat) {
			minLat = currentLocation.coordinate.latitude;
		}
		if(currentLocation.coordinate.longitude > maxLon) {
			maxLon = currentLocation.coordinate.longitude;
		}
		if(currentLocation.coordinate.longitude < minLon) {
			minLon = currentLocation.coordinate.longitude;
		}
	}
	
	MKCoordinateRegion region;
	region.center.latitude     = (maxLat + minLat) / 2;
	region.center.longitude    = (maxLon + minLon) / 2;
	region.span.latitudeDelta  = maxLat - minLat;
	region.span.longitudeDelta = maxLon - minLon;
	
	[map setRegion:region animated:NO];
    
    [progressAlert dismissWithClickedButtonIndex: 0  animated:YES]; 
}

#pragma mark - Host Checked
- (NSString *) getIPAddressForHost: (NSString *) theHost
{
	struct hostent *host = gethostbyname([theHost UTF8String]);
	
    if (host == NULL) {
        herror("resolv");
		return NULL;
	}
	
	struct in_addr **list = (struct in_addr **)host->h_addr_list;
	NSString *addressString = [NSString stringWithUTF8String:inet_ntoa(*list[0])];
	return addressString;
}

// Direct from Apple. Thank you Apple
- (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)address
{
	if (!IPAddress || ![IPAddress length]) {
		return NO;
	}
	
	memset((char *) address, sizeof(struct sockaddr_in), 0);
	address->sin_family = AF_INET;
	address->sin_len = sizeof(struct sockaddr_in);
	
	int conversionResult = inet_aton([IPAddress UTF8String], &address->sin_addr);
	if (conversionResult == 0) {
		NSAssert1(conversionResult != 1, @"Failed to convert the IP address string into a sockaddr_in: %@", IPAddress);
		return NO;
	}
	
	return YES;
}

- (BOOL) hostAvailable: (NSString *) theHost
{
    
	NSString *addressString = [self getIPAddressForHost:theHost];
	if (!addressString)
	{
		printf("Error recovering IP address from host name\n");
		return NO;
	}
	
	struct sockaddr_in address;
	BOOL gotAddress = [self addressFromString:addressString address:&address];
	
	if (!gotAddress)
	{
		printf("Error recovering sockaddr address from %s\n", [addressString UTF8String]);
		return NO;
	}
	
	SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&address);
	SCNetworkReachabilityFlags flags;
	
	BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
	CFRelease(defaultRouteReachability);
	
	if (!didRetrieveFlags)
	{
		printf("Error. Could not recover network reachability flags\n");
		return NO;
	}
	
	BOOL isReachable = flags & kSCNetworkFlagsReachable;
	return isReachable ? YES : NO;;
}

- (void)alertWaiting{
    progressAlert = [[UIAlertView alloc] initWithTitle:@"路徑規劃資料載入中"
                                               message:@"請等待..."
                                              delegate: self
                                     cancelButtonTitle: nil
                                     otherButtonTitles: nil];
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.frame = CGRectMake(139.0f-57/2.0f, 68.0f, 57.0f, 57.0f);
    [progressAlert addSubview:activityView];
    [activityView startAnimating];
    [activityView release];
    [progressAlert show];
}

- (void)calculateDirections {
    if ([self hostAvailable:weburi]){
        if (httpSemaphore) {
            httpSemaphore = NO;
            //資料載入
            requestObj = nil;
            CLLocationCoordinate2D f = source.coordinate;
            CLLocationCoordinate2D t = destination.coordinate;
            NSString* saddr = [NSString stringWithFormat:@"%f,%f", f.latitude, f.longitude];
            NSString* daddr = [NSString stringWithFormat:@"%f,%f", t.latitude, t.longitude];
            
            NSString* urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?output=dragdir&saddr=%@&daddr=%@&hl=%@", saddr, daddr, [[NSLocale currentLocale] localeIdentifier]];
            // by car:
            NSLog(@"urlString=%@",urlString);
            
            //NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            NSString *percentEscapedString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            requestObj = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:percentEscapedString]];
            [requestObj addRequestHeader:@"Content-Type" value:@"application/json"];
            [requestObj addRequestHeader:@"Content-Type" value:@"text/json"];
            [requestObj addRequestHeader:@"Content-Type" value:@"text/javascript"];
            [requestObj setRequestMethod:@"POST"];
            [requestObj setTimeOutSeconds:60];
            [requestObj setDelegate:self];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"wifi"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"gprs"]) {
                //do smth
                [self alertWaiting];
                // http service
                [requestObj startAsynchronous];
            }
            else
            {
                [KGDiscreetAlertView showDiscreetAlertWithText:@"設備網路服務異常!" inView:self.view maxWidth:500 delay:1.5];
            }
        }
    }
    else{
        [KGDiscreetAlertView showDiscreetAlertWithText:@"Host服務回應異常!" inView:self.view maxWidth:500 delay:1.5];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    //Example to download google's source and print out the urls of all the images
    //NSLog(@"Content will be %llu bytes in size",[request contentLength]);
    //[httpHUD hide:YES afterDelay:0.01];
    
    if ([request responseString]) {
        @try {
            NSData *data = [[request responseString] dataUsingEncoding:NSUTF8StringEncoding];
            NSString* responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //NSString* data = [[request responseString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            //NSString* responseString = data;
            
            NSLog(@"responseString=%@",responseString);
            // TODO: better parsing. Regular expression?
            
            NSInteger a = [responseString indexOf:@"points:\"" from:0];
            NSInteger b = [responseString indexOf:@"\",levels:\"" from:a] - 10;
            
            NSInteger c = [responseString indexOf:@"tooltipHtml:\"" from:0];
            NSInteger d = [responseString indexOf:@"(" from:c];
            NSInteger e = [responseString indexOf:@")\"" from:d] - 2;
            
            NSString* info = [[responseString substringFrom:d to:e] stringByReplacingOccurrencesOfString:@"\\x26#160;" withString:@""];
            NSLog(@"tooltip %@", info);
            self.title = info;
            
            NSString* encodedPoints = [responseString substringFrom:a to:b];
            NSArray* steps = [self decodePolyLine:[encodedPoints mutableCopy]];
            if (steps && [steps count] > 0) {
                [self setRoutePoints:steps];
                //} else if (!steps) {
                //	[self showError:@"No se pudo calcular la ruta"];
            } else {
                // TODO: show error
                [KGDiscreetAlertView showDiscreetAlertWithText:@"無法規劃路徑!" inView:self.view maxWidth:500 delay:1.5];
                [progressAlert dismissWithClickedButtonIndex: 0  animated:YES];
            }
            
            [responseString release];
        }
        @catch (NSException * e) {
            // TODO: show error
            [KGDiscreetAlertView showDiscreetAlertWithText:@"無法規劃路徑!" inView:self.view maxWidth:500 delay:1.5];
            [progressAlert dismissWithClickedButtonIndex: 0  animated:YES]; 
        }
    }
}

- (void)requestStarted:(ASIHTTPRequest *)request{
    NSLog(@"requestStarted...");
}

- (void)requestFailed:(ASIHTTPRequest *)request{
    //NSLog(@"requestFailed...");
    //取消警告視窗
    httpSemaphore = YES;
    [KGDiscreetAlertView showDiscreetAlertWithText:@"Network服務異常!" inView:self.view maxWidth:500 delay:1.5];
}

// Decode a polyline.
// See: http://code.google.com/apis/maps/documentation/utilities/polylinealgorithm.html
- (NSMutableArray *)decodePolyLine:(NSMutableString *)encoded {
	[encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"
								options:NSLiteralSearch
								  range:NSMakeRange(0, [encoded length])];
	NSInteger len = [encoded length];
	NSInteger index = 0;
	NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
	NSInteger lat=0;
	NSInteger lng=0;
	while (index < len) {
		NSInteger b;
		NSInteger shift = 0;
		NSInteger result = 0;
		do {
			b = [encoded characterAtIndex:index++] - 63;
			result |= (b & 0x1f) << shift;
			shift += 5;
		} while (b >= 0x20);
		NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
		lat += dlat;
		shift = 0;
		result = 0;
		do {
			b = [encoded characterAtIndex:index++] - 63;
			result |= (b & 0x1f) << shift;
			shift += 5;
		} while (b >= 0x20);
		NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
		lng += dlng;
		NSNumber *latitude = [[[NSNumber alloc] initWithFloat:lat * 1e-5] autorelease];
		NSNumber *longitude = [[[NSNumber alloc] initWithFloat:lng * 1e-5] autorelease];
		// printf("[%f,", [latitude doubleValue]);
		// printf("%f]", [longitude doubleValue]);
		CLLocation *loc = [[[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]] autorelease];
		[array addObject:loc];
	}
	
	return array;
}

-(void) backButtonTapped{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    httpSemaphore = YES;
    isInit = NO;
    if (!isInit) {
        //客制化標頭文字
        UIImage *headerimage = [UIImage imageNamed:isiPad()?@"header_bg-ipad":@"header_bg"];
        UIImageView *header = [[UIImageView alloc] initWithImage:headerimage];
        [header setFrame:CGRectMake(isiPad()?-7:-5, isiPad()?80:20, headerimage.size.width, headerimage.size.height)];
        CGRect frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, headerimage.size.height);
        UIView *myheader = [[UIView alloc] init];
        [myheader addSubview:header];
        [header release];
        [myheader setBackgroundColor:[UIColor clearColor]];
        [myheader setFrame:frame];
        self.navigationItem.titleView = myheader;
        [myheader release];
        UIImage *backimage = [UIImage imageNamed:isiPad()?@"btn_back-ipad":@"btn_back"];
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectMake(0, isiPad()?100:30, backimage.size.width, backimage.size.height)];
        //[b setTitle:@"首頁" forState:UIControlStateNormal];
        [b addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [b setImage:backimage forState:UIControlStateNormal];
        [self.navigationItem.titleView addSubview:b];
        [b release];
        
        map = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-navigationbarheight)];
        [map setMapType:MKMapTypeStandard];//MKMapTypeStandard];
        //設置為可以顯示用戶位置
        //[map setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:NO];
        map.delegate = self;
        if (![map superview]) {
            [self.view addSubview:map];
            [self.view bringSubviewToFront:map];
        }
    }
    
}

- (void)setPathDirection:(MKPointAnnotation*) target{
    locmanager = [[CLLocationManager alloc] init];
    locmanager. delegate  = self;
    locmanager.desiredAccuracy = kCLLocationAccuracyBest;
    locmanager.distanceFilter   =  1.0f ;
    [locmanager startUpdatingLocation];
    
    self.destination = target;
}

- ( void )locationManager:(CLLocationManager * )manager
      didUpdateToLocation:(CLLocation * )newLocation
             fromLocation:(CLLocation * )oldLocation{
    MKPointAnnotation* annotation = [[MKPointAnnotation alloc] init];
    annotation.title = @"目前位置";
    annotation.coordinate = [newLocation coordinate];
    //annotation.coordinate = CLLocationCoordinate2DMake(22.04578343694601, 120.69891214370727);
    if (!gpsSemaphore) {
        gpsSemaphore = YES;
        self.source = annotation;
        [self caculatedPath];
    }
    
    [annotation release];
    // 如果擷取到位置就停止該感測器
    [locmanager stopUpdatingLocation];
}

- (void)dealloc
{
    
    if (isInit) {
        map.delegate = nil;
        [source release];
        [destination release];
        [routeLine release];
        [map release];
    }
    
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)caculatedPath{
    [map addAnnotation:self.source];
    [map addAnnotation:self.destination];
    
    [map setCenterCoordinate:self.source.coordinate animated:NO];
    
    [self calculateDirections];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //系統默認不支持旋轉功能
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
