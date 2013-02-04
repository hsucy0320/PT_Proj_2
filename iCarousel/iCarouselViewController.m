//
//  iCarouselViewController.m
//  i高醫
//
//  Created by hsucy0320 on 2011/10/14.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "iCarouselViewController.h"

@interface iCarouselViewController ()

@property (nonatomic, assign) BOOL wrap;

@end

@implementation iCarouselViewController

@synthesize carousel;
@synthesize wrap;
@synthesize poiObj = _poiObj;
@synthesize poiImages=_poiImages;

#define ITEM_SPACING (isiPad()?420:210)
#define ICONWIDTH (isiPad()?480:240)
#define ICONHEIGHT (isiPad()?360:180)

-(id) init{
    self=[super init];
    if(self){
        bChange = YES;
        //set up data
        wrap = YES;
        flag = YES;
        isPlay = NO;
        imageindex = 0;
    }
    return self;
}

- (void)dealloc
{
    [connection cancel]; //in case the URL is still downloading
	[connection release];
	[imgdata release]; 
    
    [carousel release];
    //[items release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

// when there is some error with web service
-(void)connection:(NSURLConnection *)_connection didFailWithError:(NSError *)error
{
    //發生錯誤
    if (isAsycBtn) {
        [connect release];
        
    }
    else{
        [_connection release];
    }
}

-(void) backButtonTapped{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    
    //configure carousel
    carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, isiPad()?50 : 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    [carousel setBackgroundColor:[UIColor clearColor]];
    //carousel.dataSource = self;
    carousel.contentOffset = CGSizeMake(0, -15);
    carousel.type = iCarouselTypeCoverFlow;
    
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
    
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-70,isiPad()?110:20, 57.0f, 57.0f);
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"poibg"]]];
}

- (void)setViewDidLoad
{
    //----------------------------
    btnspinner = [[UIActivityIndicatorView  alloc] initWithFrame:CGRectMake(0,0,50,50)];
    
    UIImage *image = [UIImage imageNamed:isiPad()?@"photo_bg-ipad":@"photo_bg"];
    UIImageView *photo_bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, image.size.height/(isiPad()?2:1))];
    [photo_bg setImage:image];
    [self.view addSubview:photo_bg];
    [self.view bringSubviewToFront:photo_bg];
    [photo_bg release];
    [self.view addSubview:carousel];
    
    //=======加入標頭
    lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(isiPad()?30:15, isiPad()?535:(isPhone568?250:200), [[UIScreen mainScreen] bounds].size.width, 40)];
    lblTitle.backgroundColor = [UIColor clearColor]; // [UIColor brownColor];
    lblTitle.font = isiPad()?[UIFont fontWithName:@"Arial" size:20.0]:[UIFont fontWithName:@"Arial" size:16.0];
    lblTitle.shadowColor = [UIColor grayColor];
    lblTitle.shadowOffset = CGSizeMake(1,1);
    lblTitle.textColor = [UIColor redColor];
    lblTitle.textAlignment = UITextAlignmentLeft;
    [self.view addSubview:lblTitle];
    
    //=======加入簡介
    UILabel *lblIntroduction = [[UILabel alloc] initWithFrame:CGRectMake(isiPad()?30:15, lblTitle.frame.origin.y+lblTitle.frame.size.height, [[UIScreen mainScreen] bounds].size.width, 50)];
    lblIntroduction.backgroundColor = [UIColor clearColor];
    lblIntroduction.font = isiPad()?[UIFont fontWithName:@"Arial" size:20.0]:[UIFont fontWithName:@"Arial" size:16.0];
    lblIntroduction.textColor = [UIColor blackColor];
    lblIntroduction.text=@"簡介\n-----------------------------";
    lblIntroduction.numberOfLines = 2;
    lblIntroduction.textAlignment = UITextAlignmentLeft;
    [self.view addSubview:lblIntroduction];
    [lblIntroduction release];
    
    //=======加入說明
    txtView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, ([[UIScreen mainScreen] bounds].size.width-30), isiPad()?([[UIScreen mainScreen] bounds].size.height-640):([[UIScreen mainScreen] bounds].size.height-(isPhone568?370:320)))];
    txtView.autoresizingMask = ( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight );
    txtView.textAlignment = UITextAlignmentLeft;
    txtView.backgroundColor = [UIColor clearColor];
    [txtView setEditable:NO];
    [txtView setBackgroundColor:[UIColor clearColor]];
    txtView.font = isiPad()?[UIFont fontWithName:@"Arial" size:20.0]:[UIFont fontWithName:@"Arial" size:16.0];
    [txtView setTextColor:[UIColor blackColor]];
    txtView.text = [NSString stringWithFormat:@"聯絡電話:%@\n營業時間:%@\n%@",[self.poiObj objectForKey:@"tel"],[self.poiObj objectForKey:@"openhour"],[self.poiObj objectForKey:@"htmlcontent"]];
    //=======加入Scroll
    scroller = [[UIScrollView alloc] initWithFrame:CGRectMake(15, isiPad()?620:isPhone568?330:280, ([[UIScreen mainScreen] bounds].size.width-30), isiPad()?([[UIScreen mainScreen] bounds].size.height-620):([[UIScreen mainScreen] bounds].size.height-(isPhone568?330:280)))];
    scroller.contentSize = CGSizeMake(isiPad()?450:220, isiPad()?390:160);
    //[scroller setBackgroundColor:[UIColor grayColor]];
    scroller.showsVerticalScrollIndicator = YES;
    [scroller setCanCancelContentTouches:NO];
    scroller.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    [scroller setScrollEnabled:YES];
    [scroller addSubview:txtView];
    [self.view addSubview:scroller];
    
    
    [self.view bringSubviewToFront:scroller];
    tempViews = [[NSMutableArray alloc] init];

    [self initView];
}

-(void) initView{
    
    //依據大小先進行調整
    UIImage *imgbtnMyKMU;
    imgbtnMyKMU = [UIImage imageNamed:@"unknown.png"];
    float scale=0;
    if (imgbtnMyKMU.size.width/ICONWIDTH>imgbtnMyKMU.size.height/ICONHEIGHT) {
        scale = imgbtnMyKMU.size.width/ICONWIDTH;
    }
    else{
        scale = imgbtnMyKMU.size.height/ICONHEIGHT;
    }
    imgbtnMyKMU = [self imageByScalingToSize:CGSizeMake(imgbtnMyKMU.size.width/scale, imgbtnMyKMU.size.height/scale) sourceImage:imgbtnMyKMU];
    
    NSArray *items = [[self.poiObj objectForKey:@"imageurl"] componentsSeparatedByString:@"|"];
    _poiImages = [[NSMutableArray alloc] initWithArray:items];
    
    lblTitle.text = [self.poiObj objectForKey:@"title"];
    
    for (int i=0; i< [self.poiImages count];i++) {
        //依據大小先進行調整
        [tempViews addObject:imgbtnMyKMU];
    }
    
    if ([self.poiImages count]>0)
    {
        carousel.delegate=self;
        carousel.dataSource = self;
        [carousel reloadData];
        
        //延遲兩秒後，開始進行非同步圖片下載
        [self performSelector:@selector(AsynchronousImageLoading:) withObject:@"XD" afterDelay:0.5];
    }
}

#pragma 啓動非同步圖片下載Timer
- (void)AsynchronousImageLoading:(NSString *)label {
    [NSTimer scheduledTimerWithTimeInterval:0.5f
                                     target:self
                                   selector:@selector(executeLoadImage:)
                                   userInfo:nil
                                    repeats:YES];
    [self.navigationItem.titleView addSubview:spinner];
    [spinner startAnimating];
}

#pragma 非同步圖片下載Timer Event
- (void)executeLoadImage:(NSTimer *)theTimer {
    if (flag) {
        flag = NO;
        
        // 尚未完成全部縮圖載入
        if (imageindex==0) {
            bfullLoading = NO;
        }
        
        if ([self.poiImages count]==imageindex) {
            [theTimer invalidate];
            [spinner removeFromSuperview];
            [spinner stopAnimating];
            // 加入路徑規劃
            UIButton *btndirect =[[UIButton alloc] init];
            UIImage *btnway = [UIImage imageNamed:isiPad()?@"btn_way-ipad":@"btn_way"];
            [btndirect setBackgroundImage:btnway forState:UIControlStateNormal];
            btndirect.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-btnway.size.width, isiPad()?95:30, btnway.size.width, btnway.size.height);
            [btndirect addTarget:self action:@selector(mapPathDirection:) forControlEvents:UIControlEventTouchUpInside];
            [self.navigationItem.titleView addSubview:btndirect];
            [btndirect release];
            // 完成全部縮圖載入
            bfullLoading = YES;
        }
        else
        {
            NSString *_Obj = [self.poiImages objectAtIndex:imageindex];
            _Obj = [NSString stringWithFormat:@"http://60.249.202.111/PTCulture/picDB/%@",_Obj];
            NSString *percentEscapedString = [_Obj  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            [self loadImageFromURL:[NSURL URLWithString:percentEscapedString]];
        }
    }
}

-(void)mapPathDirection:(id)sender
{
    DirectionsMap *myDirectionsMap = [[DirectionsMap alloc] init];
    
    [myDirectionsMap.view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-navigationbarheight)];
    
    MKPointAnnotation* target = [[MKPointAnnotation alloc] init];
    target.title = [NSString stringWithFormat:@"%@", [self.poiObj objectForKey:@"title"]?[self.poiObj objectForKey:@"title"]:[self.poiObj objectForKey:@"name"]];
    target.coordinate = CLLocationCoordinate2DMake([[self.poiObj objectForKey:@"lat"] floatValue], [[self.poiObj objectForKey:@"lon"] floatValue]);
    
    [myDirectionsMap setPathDirection:target];
    [target release];
    
    [self.navigationController pushViewController:myDirectionsMap animated:YES];
    [myDirectionsMap release];
}

- (void)loadImageFromURL:(NSURL*)url{
    if (connection!=nil) { [connection release]; } //in case we are downloading a 2nd image
	if (imgdata!=nil) { [imgdata release]; }
	
	NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self]; //notice how delegate set to self object
}


//the URL connection calls this repeatedly as data arrives
- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
    if (isAsycBtn) {
        //收到封包，將收到的資料塞進緩衝中並修改進度條
        [tempData appendData:incrementalData];
        
        double ex = expectedLength;
        gsprg_Bar.progress = ([tempData length] / ex);
        //NSLog(@"gsprg_Bar.progress=%f",gsprg_Bar.progress);
    }
    else{
        if (imgdata==nil) { imgdata = [[NSMutableData alloc] initWithCapacity:2048]; }
        [imgdata appendData:incrementalData];
    }
}

//the URL connection calls this once all the data has downloaded
- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
    if (isAsycBtn) {
        MWPhoto *photo = [MWPhoto photoWithImage:[UIImage imageWithData:tempData]];
        
        NSMutableArray *photos = [[NSMutableArray alloc] init];
        [photos addObject:photo];
        
        // Create browser
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithPhotos:photos];
        //[browser setInitialPageIndex:0]; // Can be changed if desired
        [self.navigationController pushViewController:browser animated:YES];
        [browser release];
        [photos release];
        
        
        [progressAlert dismissWithClickedButtonIndex: 0  animated:YES];
        
        
        isAsycBtn = NO;
    }
    else{
        //so self data now has the complete image
        [connection release];
        connection=nil;
        
        //make an image view for the image
        UIImage* myUIImage = [[[UIImage alloc] initWithData:imgdata] autorelease];
        if (myUIImage) {
            //依據大小先進行調整
            
            float scale=0;
            if (myUIImage.size.width/ICONWIDTH>myUIImage.size.height/ICONHEIGHT) {
                scale = myUIImage.size.width/ICONWIDTH;
            }
            else{
                scale = myUIImage.size.height/ICONHEIGHT;
            }
            myUIImage = [self imageByScalingToSize:CGSizeMake(myUIImage.size.width/scale, myUIImage.size.height/scale) sourceImage:myUIImage];
            [tempViews replaceObjectAtIndex:imageindex withObject:myUIImage];
            
            [carousel reloadData];
            
        }
        [imgdata release]; //don't need this any more, its in the UIImageView now
        flag = YES;
        imageindex ++;
        imgdata=nil;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.carousel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark iCarousel methods
#define DEGREES_TO_RADIANS(d) (d * M_PI / 180)

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [self.poiImages count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index
{
    //create a numbered button
    UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, ICONWIDTH, ICONHEIGHT)] autorelease];
    
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = index;
    
    //========
    if ([tempViews count]>0) {
        // Image Layer
        //UIImage *image = [tempViews objectAtIndex:index];
        // create the reflection layer
        /*
        CALayer *reflectionLayer = [CALayer layer];
        reflectionLayer.contents = (id)image.CGImage;
        reflectionLayer.opacity = 0.4;
        reflectionLayer.frame = CGRectOffset(CGRectMake((button.frame.size.width-image.size.width)/2, (button.frame.size.height-image.size.height)/2+5, image.size.width, image.size.height/3), 0.0,  image.size.height);
        reflectionLayer.transform = CATransform3DMakeScale(1.0, -1,  1); // flip the y-axis
        reflectionLayer.sublayerTransform = reflectionLayer.transform;
        [button.layer addSublayer:reflectionLayer];
         */
        //========
        [button setImage:[tempViews objectAtIndex:index] forState:UIControlStateNormal];
    }
    
    return button;
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
	//note: placeholder views are only displayed on some carousels if wrapping is disabled
	return 2;
}

- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index
{
    
	//create a placeholder view
	UIView *view = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"info.png"]] autorelease];
	UILabel *label = [[[UILabel alloc] initWithFrame:view.bounds] autorelease];
	label.text = (index == 0)? @"[": @"]";
	label.backgroundColor = [UIColor clearColor];
	label.textAlignment = UITextAlignmentCenter;
	label.font = [label.font fontWithSize:50];
	[view addSubview:label];
	return view;
}

-(UIImage*) imageByScalingToSize:(CGSize) targetSize sourceImage:(UIImage*)sourceImage
{
    UIGraphicsBeginImageContext(targetSize);
    [sourceImage drawInRect:CGRectMake(0, 0.0, targetSize.width, targetSize.height)];
    UIImage *newimage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newimage;
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel
{
    //limit the number of items views loaded concurrently (for performance reasons)
    return [self.poiImages count];
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel
{
    //slightly wider than item view
    return ITEM_SPACING;
}

- (CATransform3D)carousel:(iCarousel *)_carousel transformForItemView:(UIView *)view withOffset:(CGFloat)offset
{
    //implement 'flip3D' style carousel
    
    //set opacity based on distance from camera
    view.alpha = 1.0 - fminf(fmaxf(offset, 0.0), 1.0);
    
    //do 3d transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = self.carousel.perspective;
    transform = CATransform3DRotate(transform, M_PI / 8.0, 0, 1.0, 0);
    return CATransform3DTranslate(transform, 0.0, 0.0, offset * carousel.itemWidth);
}

- (BOOL)carouselShouldWrap:(iCarousel *)_carousel
{
    
    //wrap all carousels
    return YES;
}

#pragma mark - Http Asycornized Events

- (void)connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)aResponse {  //連線建立成功
	expectedLength = [aResponse expectedContentLength]; //儲存檔案長度
}

#pragma mark Button tap event

#pragma make data view data source
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

- (void)alertWaiting{
    progressAlert = [[UIAlertView alloc] initWithTitle:@"展覽資料載入中"
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

- (void)buttonTapped:(UIButton *)sender
{
    NSString *_Obj = [self.poiImages objectAtIndex:sender.tag];
    if (bfullLoading) {
        if ([self hostAvailable:weburi]){
            isAsycBtn = YES;
            
            // 非同步載入
            //取得資料顯示圖片
            _Obj = [NSString stringWithFormat:@"http://60.249.202.111/PTCulture/picDB/%@",_Obj];
            NSString *percentEscapedString = [_Obj stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#ifdef DEBUG
            NSLog(@"percentEscapedString=%@",percentEscapedString);
#endif
            NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
            [request setURL:[NSURL URLWithString:percentEscapedString]];
            [request setHTTPMethod:@"GET"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setValue:@"Mobile Safari 1.1.3 (iPhone; U; CPU like Mac OS X; en)" forHTTPHeaderField:@"User-Agent"];
            [request setTimeoutInterval:httptimeout];
            tempData = [NSMutableData alloc];
            connect = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            //計算response time
            
            [self alertWaiting];
            
        }
        else{
            [KGDiscreetAlertView showDiscreetAlertWithText:@"Host服務回應異常。"
                                                    inView:self.view maxWidth:500 delay:1.5];
        }
    }
    else{
        [KGDiscreetAlertView showDiscreetAlertWithText:@"資料尚未載入完全，請稍候..."
                                                inView:self.view maxWidth:500 delay:1.5];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    
	// Super
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
}

@end
