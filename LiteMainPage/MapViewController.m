//
//  HospitalViewController.m
//  m-Order
//
//  Created by HSU CHIH YUAN on 12/8/3.
//  Copyright (c) 2012年 HSU CHIH YUAN. All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController ()

@end

@implementation MapViewController

@synthesize dataset;

#pragma Host Checked
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

#pragma 非同步載入壓縮圖片檔案，並進行解壓縮 Function
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark- HTTP Function
- (void)getUpdateData {
    
    if ([self hostAvailable:weburi]){
        if (httpSemaphore) {
            httpSemaphore = NO;
            //資料載入
            requestObj = nil;
            //初始化Documents路径
            downloadPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/pois.json"] retain];
            
            NSString *percentEscapedString = [[NSString stringWithFormat:@"http://%@:%@/PTCulture/picDB/pois.json", weburi, webport] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *updateurl = [NSURL URLWithString:percentEscapedString];
            NSLog(@"updateString=%@",percentEscapedString);
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"wifi"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"gprs"]) {
                //do smth
                [self updateAlertWaiting];
                // http service
                requestUpdate = [[[NSMutableURLRequest alloc] init] autorelease];
                [requestUpdate setURL:updateurl];
                [requestUpdate setHTTPMethod:@"GET"];
                [requestUpdate setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                [requestUpdate setValue:@"Mobile Safari 1.1.3 (iPhone; U; CPU like Mac OS X; en)" forHTTPHeaderField:@"User-Agent"];
                tempData = [NSMutableData alloc];
                [requestUpdate setTimeoutInterval:httptimeout];
                connect = [[NSURLConnection alloc] initWithRequest:requestUpdate delegate:self];
            }
            else
            {
                [KGDiscreetAlertView showDiscreetAlertWithText:@"設備網路服務異常!" inView:self.view maxWidth:500 delay:1.5];
            }
        }
    }
    else{
        [KGDiscreetAlertView showDiscreetAlertWithText:@"網路不穩定，導致無法取得遠端伺服器連線!" inView:self.view maxWidth:500 delay:1.5];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{   //發生錯誤
    [connect release];
	NSLog(@"發生錯誤");
    [progressAlert dismissWithClickedButtonIndex: 0  animated:YES];
}

- (void)connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)aResponse {  //連線建立成功
    //取得狀態
	expectedLength = [aResponse expectedContentLength]; //儲存檔案長度
}
-(void) connection:(NSURLConnection *)connection didReceiveData: (NSData *) incomingData
{   //收到封包，將收到的資料塞進緩衝中並修改進度條
	[tempData appendData:incomingData];
    
    double ex = expectedLength;
    gsprg_Bar.progress = ([tempData length] / ex);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (tempData && [tempData length]>0) {
        // Save File downloadPath
        NSLog(@"downloadPath=%@",downloadPath);
        [tempData writeToFile:downloadPath atomically:YES];
        
        NSString *myjsondata = [[NSString alloc] initWithData:tempData
                                                     encoding:NSUTF8StringEncoding];
        if (myjsondata) {
            dataset = [[NSMutableArray alloc] init];
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *json = [parser objectWithString:myjsondata];
            NSDictionary *items = [json objectForKey:@"items"];
            //NSLog(@"items=%d",[items count]);
            for (NSMutableDictionary *obj in items) {
                [dataset addObject:obj];
            }
            [parser release];
            
            // 取消警告視窗
            httpSemaphore = YES;
            
            // 轉換POI為地圖標籤2
            [self mapKitData];
        }
        [myjsondata release];
    }
    [progressAlert dismissWithClickedButtonIndex: 0  animated:YES];
}

#pragma mark - 暫停下載
- (void)pauseDownload
{
    //暫停
    [connect cancel];//取消请求
}

- (void)updateAlertWaiting{
    progressAlert = [[UIAlertView alloc] initWithTitle:@"更新資料載入中"
                                               message:@"請等待..."
                                              delegate: self
                                     cancelButtonTitle: nil
                                     otherButtonTitles: nil];
    
    gsprg_Bar = [[GSProgressView alloc] initWithFrame:CGRectMake(120, 75, 50, 50)];
    gsprg_Bar.progress = 0.0;
    gsprg_Bar.color = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
    [progressAlert addSubview:gsprg_Bar];
    [progressAlert show];
}

- (void)alertWaiting{
    progressAlert = [[UIAlertView alloc] initWithTitle:@"景點載入中"
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

- (void)dealloc
{
    
    if (isInit) {
        
        if (mapView) {
            mapView.delegate = nil;
            [mapView release];
        }
        
        [dataset release];
    }
	
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        
        // Defaults
        //self.title = @"中華電信";
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) backButtonTapped{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
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
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [self.view setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"listbg"]]];
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    httpSemaphore = YES;
    isInit = NO;
    if (!isInit) {
        
        mapView = [[REVClusterMapView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-navigationbarheight)];
        [mapView setMapType:MKMapTypeStandard];//MKMapTypeStandard];
        // 設置為可以顯示用戶位置
        // [mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:NO];
        mapView.delegate = self;
        [self.view addSubview:mapView];
        
        [self alertWaiting];
        //初始化文件路徑
        NSString *_path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:[NSString stringWithFormat:@"pois.json"]];
        //讀取文件
        if (![[NSFileManager defaultManager] fileExistsAtPath:_path]) {
            _path = [[NSBundle mainBundle] pathForResource:@"pois" ofType:@"json"];
        }
        // 解析資料
        if (_path) {
            NSString *myjsondata = [NSString stringWithContentsOfFile:_path
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil];
            if (myjsondata) {
                dataset = [[NSMutableArray alloc] init];
                SBJsonParser *parser = [[SBJsonParser alloc] init];
                NSDictionary *json = [parser objectWithString:myjsondata];
                NSDictionary *items = [json objectForKey:@"items"];
                //NSLog(@"items=%d",[items count]);
                for (NSMutableDictionary *obj in items) {
                    [dataset addObject:obj];
                }
                [parser release];
                
                // 取消警告視窗
                httpSemaphore = YES;
                
                // 轉換POI為地圖標籤2
                [self mapKitData];
            }
        }
        
        [progressAlert dismissWithClickedButtonIndex: 0  animated:YES];
        
        isInit = YES;
    }
}

- (void)getDataFromWSInterface{
    [self performSelector:@selector(getUpdateData) withObject:self afterDelay:0.2];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
}

#pragma mark - 轉換poi to mkannotation
-(void)mapKitData{
    //查詢資料庫取出全部的資料，放到messages
    if(mapView.annotations)[mapView removeAnnotations:mapView.annotations];
    //把POI資料點加入MAP內
    NSMutableArray * mapdataset = [[NSMutableArray alloc] init];
    for (int i=0; i<[dataset count]; i++) {
        REVClusterPin *annotation = [[REVClusterPin alloc] init];
        annotation.content = [dataset objectAtIndex:i];
        annotation.title = [annotation.content objectForKey:@"title"];
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = [[annotation.content objectForKey:@"lat"] floatValue];
        coordinate.longitude = [[annotation.content objectForKey:@"lon"] floatValue];
        annotation.coordinate = coordinate;
        [mapdataset addObject:annotation];
        [annotation release];
    }
    [mapView addAnnotations:mapdataset];
    
    if ([mapdataset count]>0)
    {
        MKCoordinateRegion region = MKCoordinateRegionForMapRect([self getMapRectUsingAnnotations:mapdataset]);
        [mapView setRegion:region];
    }
    [mapdataset release];
}

#pragma mark - POI事件
-(void)markerClickEvent:(NSMutableDictionary*)obj{
    if (!clickSemaphore) {
        clickSemaphore = YES;
        if ([obj objectForKey:@"htmlcontent"]) {
            NSArray *items = [[obj objectForKey:@"imageurl"] componentsSeparatedByString:@"|"];
            if ([items count]>1) {
                iCarouselViewController *myiCarouselViewController = [[iCarouselViewController alloc]init];
                [myiCarouselViewController.view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
                
                myiCarouselViewController.title = [obj objectForKey:@"title"];
                myiCarouselViewController.poiObj = obj;
                [myiCarouselViewController setViewDidLoad];
                [self.navigationController pushViewController:myiCarouselViewController animated:YES];
                [myiCarouselViewController release];
            }
            else{
                POIDetailViewController *myPOIDetailViewController = [[POIDetailViewController alloc] init];
                myPOIDetailViewController.dataElement = obj;
                myPOIDetailViewController.title = [obj objectForKey:@"title"];
                [self.navigationController pushViewController:myPOIDetailViewController animated:YES];
                [myPOIDetailViewController release];
            }
        }
        else{
            [KGDiscreetAlertView showDiscreetAlertWithText:@"景點無細部資料..." inView:self.view maxWidth:500 delay:1.5];
        }
        
        clickSemaphore = NO;
    }
    
}

#pragma mark - 動態範圍
/* This returns a rectangle bounding all of the pins within the supplied
 array */
- (MKMapRect) getMapRectUsingAnnotations : (NSMutableArray *)data {
    MKMapPoint points[[data count]];
    
    for (int i = 0; i < [data count]; i++) {
        REVClusterPin *annotation = [data objectAtIndex:i];
        points[i] = MKMapPointForCoordinate(annotation.coordinate);
    }
    MKPolygon *poly = [MKPolygon polygonWithPoints:points count:[data count]];
    
    return [poly boundingMapRect];
}

#pragma mark - 計算距離
- (CLLocationDistance)distanceBetweenCoordinate:(CLLocationCoordinate2D)originCoordinate andCoordinate:(CLLocationCoordinate2D)destinationCoordinate {
    
    CLLocation *originLocation = [[CLLocation alloc] initWithLatitude:originCoordinate.latitude longitude:originCoordinate.longitude];
    CLLocation *destinationLocation = [[CLLocation alloc] initWithLatitude:destinationCoordinate.latitude longitude:destinationCoordinate.longitude];
    CLLocationDistance distance = [originLocation distanceFromLocation:destinationLocation];
    [originLocation release];
    [destinationLocation release];
    
    return distance;
}

- (float)angleFromCoordinate:(CLLocationCoordinate2D)source toCoordinate:(CLLocationCoordinate2D)destination {
    
    float deltaLongitude = destination.longitude - source.longitude;
    float deltaLatitude = destination.latitude - source.latitude;
    float angle = (M_PI * .5f) - atan(deltaLatitude / deltaLongitude);
    
    if (deltaLongitude > 0)      return angle;
    else if (deltaLongitude < 0) return angle + M_PI;
    else if (deltaLatitude < 0)  return M_PI;
    
    return 0.0f;
}

#pragma mark - Map Events
#pragma mark - AnnotationView's UIControl 被點擊後的動作反應
-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if (!clickSemaphore) {
        clickSemaphore = YES;
        
        NSMutableDictionary *obj = ((REVClusterPin*)view.annotation).content;
        //設定院所詳細資料
        if ([obj objectForKey:@"htmlcontent"]) {
            NSArray *items = [[obj objectForKey:@"imageurl"] componentsSeparatedByString:@"|"];
            if ([items count]>1) {
                iCarouselViewController *myiCarouselViewController = [[iCarouselViewController alloc]init];
                [myiCarouselViewController.view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
                
                myiCarouselViewController.title = [obj objectForKey:@"title"];
                myiCarouselViewController.poiObj = obj;
                [myiCarouselViewController setViewDidLoad];
                [self.navigationController pushViewController:myiCarouselViewController animated:YES];
                [myiCarouselViewController release];
            }
            else{
                POIDetailViewController *myPOIDetailViewController = [[POIDetailViewController alloc] init];
                myPOIDetailViewController.dataElement = obj;
                myPOIDetailViewController.title = [obj objectForKey:@"title"];
                [self.navigationController pushViewController:myPOIDetailViewController animated:YES];
                [myPOIDetailViewController release];
            }
        }
        else{
            [KGDiscreetAlertView showDiscreetAlertWithText:@"景點無細部資料..." inView:self.view maxWidth:500 delay:1.5];
        }
        
        clickSemaphore = NO;
    }
    
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
	/*
    if (annotation == mapView.userLocation) return nil;
    
    static NSString *AnnotationViewID = @"annotationViewID";
    MKPinAnnotationView* pinView;
    pinView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewID] autorelease];
    pinView.pinColor = MKPinAnnotationColorPurple;
    //pinView.animatesDrop = YES;
    pinView.canShowCallout =YES;
    pinView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    //Here's where the magic happens
    //pinView.image=[UIImage imageNamed:@"cht"];
    
    return pinView;*/
    if([annotation class] == MKUserLocation.class) {
		//userLocation = annotation;
		return nil;
	}
    
    REVClusterPin *pin = (REVClusterPin *)annotation;
    
    REVClusterAnnotationView *annView;
    
    if( [pin nodeCount] > 0 ){
        pin.title = @"___";
        
        annView = (REVClusterAnnotationView*)
        [mapView dequeueReusableAnnotationViewWithIdentifier:@"cluster"];
        
        if( !annView )
            annView = (REVClusterAnnotationView*)
            [[[REVClusterAnnotationView alloc] initWithAnnotation:annotation
                                                  reuseIdentifier:@"cluster"] autorelease];
        
        annView.image = [UIImage imageNamed:@"cluster.png"];
        [annView setTextSize:annView.image.size];
        [(REVClusterAnnotationView*)annView setClusterText:
         [NSString stringWithFormat:@"%i",[pin nodeCount]]];
        
        annView.canShowCallout = NO;
    } else {
        annView = (REVClusterAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
        
        if( !annView )
            annView = (REVClusterAnnotationView*)[[[MKAnnotationView alloc] initWithAnnotation:annotation
                                                    reuseIdentifier:@"pin"] autorelease];
        
        annView.image = [UIImage imageNamed:@"pinpoint.png"];
        
        annView.calloutOffset = CGPointMake(-6.0, 0.0);
        
        annView.canShowCallout =YES;
        annView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    
    return annView;
}

- (void)mapView:(MKMapView *)_mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if (![view isKindOfClass:[REVClusterAnnotationView class]])
        return;
    
    CLLocationCoordinate2D centerCoordinate = [(REVClusterPin *)view.annotation coordinate];
    
    MKCoordinateSpan newSpan =
    MKCoordinateSpanMake(mapView.region.span.latitudeDelta/2.0,
                         mapView.region.span.longitudeDelta/2.0);
    
    [mapView setRegion:MKCoordinateRegionMake(centerCoordinate, newSpan)
              animated:YES];
}

#pragma mark - implement delegate function

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //系統默認不支持旋轉功能
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
