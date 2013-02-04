//
//  HospitalViewController.m
//  m-Order
//
//  Created by HSU CHIH YUAN on 12/8/3.
//  Copyright (c) 2012年 HSU CHIH YUAN. All rights reserved.
//

#import "ListViewController.h"

@interface ListViewController ()

@end

@implementation ListViewController

@synthesize dataset;
@synthesize tableView;
@synthesize imageDownloadsInProgress;

#define imagecellheight isiPad()?233:101
#define imagecellwidth isiPad()?327:142

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // terminate all pending download connections
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
}

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

        // terminate all pending download connections
        NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
        [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
        
        NSString *myjsondata = [[NSString alloc] initWithData:tempData
                                                     encoding:NSUTF8StringEncoding];
        if (myjsondata) {
            dataset = [[NSMutableArray alloc] init];
            self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *json = [parser objectWithString:myjsondata];
            NSDictionary *items = [json objectForKey:@"items"];
            //NSLog(@"items=%d",[items count]);
            for (NSMutableDictionary *obj in items) {
                AppRecord *temp = [[AppRecord alloc] init];
                temp.eObj = obj;
                [dataset addObject:temp];
                [temp release];
            }
            [parser release];
            
            //NSLog(@"dataset count=%d",[dataset count]);
            
            // 取消警告視窗
            httpSemaphore = YES;
            
            // 更新表單
            [tableView reloadData];
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
        [tableView release];
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
    [super viewDidLoad];
    
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
    
	// Do any additional setup after loading the view.
    httpSemaphore = YES;
    isInit = NO;
    if (!isInit) {
        
        //加入tableView
        tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height) style:UITableViewStylePlain];
        [tableView setAutoresizesSubviews:YES];
        [tableView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [tableView setDataSource:self];
        [tableView setDelegate:self];
        [tableView setBackgroundColor:[UIColor clearColor]];
        
        // UIScrollViewDelegate
        for(int i=0;i<[[tableView subviews]count];i++){
            if ([[[tableView subviews]objectAtIndex:i]isKindOfClass:[UIScrollView class]]) {
                [[[tableView subviews]objectAtIndex:i]setDelegate:self];
            }
        }
        
        //取消分隔線
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        //設定欄位高度
        UIImage *listbg = [UIImage imageNamed:isiPad()?@"list_box-ipad":@"list_box"];
        self.tableView.rowHeight = listbg.size.height;
        [self.view addSubview:tableView];
        [self.view bringSubviewToFront:tableView];
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, isiPad()?140:40)];
        self.tableView.tableHeaderView = headerView;
        [headerView release];
        
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
                self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
                SBJsonParser *parser = [[SBJsonParser alloc] init];
                NSDictionary *json = [parser objectWithString:myjsondata];
                NSDictionary *items = [json objectForKey:@"items"];
                NSLog(@"items=%d",[items count]);
                for (NSMutableDictionary *obj in items) {
                    AppRecord *temp = [[AppRecord alloc] init];
                    temp.eObj = obj;
                    [dataset addObject:temp];
                    [temp release];
                }
                [parser release];
                
                // 取消警告視窗
                httpSemaphore = YES;
            }
        }
        
        [progressAlert dismissWithClickedButtonIndex: 0  animated:YES];
        
        isInit = YES;
    }
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate)
	{
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}

#pragma mark -
#pragma mark Table cell image support

- (void)startIconDownload:(AppRecord *)appRecord forIndexPath:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.ePaperObj = appRecord;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload];
        [iconDownloader release];
    }
}

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows
{
    if ([self.dataset count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            AppRecord *appRecord = [self.dataset objectAtIndex:indexPath.row];
            
            if (!appRecord.appIcon) // avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:appRecord forIndexPath:indexPath];
                
                UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((imagecellwidth-30)/2, (imagecellheight-30)/2, 30, 30)];
                [activityIndicator setHidesWhenStopped:YES];
                [activityIndicator setActivityIndicatorViewStyle: UIActivityIndicatorViewStyleGray];
                [activityIndicator startAnimating];
                [[self.tableView cellForRowAtIndexPath:indexPath].imageView addSubview:activityIndicator];
                [activityIndicator release];
            }
            else{
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                // Display the newly loaded image
                if (cell != nil)
                {
                    for(UIView *subview in [cell.imageView subviews]) {
                        [subview removeFromSuperview];
                    }
                }
            }
        }
    }
}

// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        
        // Display the newly loaded image
        cell.imageView.image = iconDownloader.ePaperObj.appIcon;
        
        for(UIView *subview in [cell.imageView subviews]) {
            [subview removeFromSuperview];
        }
    }
    
    // Remove the IconDownloader from the in progress list.
    // This will result in it being deallocated.
    [imageDownloadsInProgress removeObjectForKey:indexPath];
}

- (void)getDataFromWSInterface{
    [self performSelector:@selector(getUpdateData) withObject:self afterDelay:0.2];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
}

#pragma mark - Table view creation (UITableViewDataSource)
/*
// This recipe adds a title for each section
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [Area_ARRAY objectAtIndex:section];
}*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;//[searchArray count];
}

// customize the number of rows in the table view
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [dataset count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!clickSemaphore) {
        clickSemaphore = YES;
        
        //取消背景
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        //get Item
        NSInteger row = [indexPath row];
        AppRecord *obj = [dataset objectAtIndex:row];
        //設定院所詳細資料
        if ([obj.eObj objectForKey:@"htmlcontent"]) {
            NSArray *items = [[obj.eObj objectForKey:@"imageurl"] componentsSeparatedByString:@"|"];
            if ([items count]>1) {
                iCarouselViewController *myiCarouselViewController = [[iCarouselViewController alloc]init];
                [myiCarouselViewController.view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
                
                myiCarouselViewController.title = [obj.eObj objectForKey:@"title"];
                myiCarouselViewController.poiObj = obj.eObj;
                [myiCarouselViewController setViewDidLoad];
                [self.navigationController pushViewController:myiCarouselViewController animated:YES];
                [myiCarouselViewController release];
            }
            else{
                POIDetailViewController *myPOIDetailViewController = [[POIDetailViewController alloc] init];
                myPOIDetailViewController.dataElement = obj.eObj;
                myPOIDetailViewController.title = [obj.eObj objectForKey:@"title"];
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

- (UITableViewCell *)tableView:(UITableView *)tableViewObj cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger TOP_LABEL_TAG = 1001;
	const NSInteger BOTTOM_LABEL_TAG = 1002;
    const NSInteger DETAIL_LABEL_TAG = 1003;
	UILabel *topLabel;
	UILabel *bottomLabel;
    UILabel *detailLabel;
    UIImage *listbg = [UIImage imageNamed:isiPad()?@"list_box-ipad":@"list_box"];
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		//
		// Create the cell.
		//
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                        reuseIdentifier:CellIdentifier] autorelease];
        
		//
		// Create the label for the top row of text
		//
		topLabel =
        [[[UILabel alloc]
          initWithFrame:
          CGRectMake(
                     listbg.size.width*2.2/5,
                     0,
                     tableView.bounds.size.width - listbg.size.width*2.2/5-(isiPad()?30:5),
                     listbg.size.height/2)]
         autorelease];
		[cell.contentView addSubview:topLabel];
        
		//
		// Configure the properties for the text that are the same on every row
		//
		topLabel.tag = TOP_LABEL_TAG;
		topLabel.backgroundColor = [UIColor clearColor];
		topLabel.textColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0];
		topLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0];
		topLabel.font = [UIFont systemFontOfSize:isiPad()?25:[UIFont labelFontSize]];
        [topLabel setTextAlignment:NSTextAlignmentLeft];
        topLabel.numberOfLines = 2;
        
		//
		// Create the label for the top row of text
		//
		bottomLabel =
        [[[UILabel alloc]
          initWithFrame:
          CGRectMake(
                     listbg.size.width*2.2/5,
                     listbg.size.height/2,
                     tableView.bounds.size.width - listbg.size.width*2.2/5-(isiPad()?30:5),
                     listbg.size.height/4-5)]
         autorelease];
		[cell.contentView addSubview:bottomLabel];
        
		//
		// Configure the properties for the text that are the same on every row
		//
		bottomLabel.tag = BOTTOM_LABEL_TAG;
		bottomLabel.backgroundColor = [UIColor clearColor];
		bottomLabel.textColor = [UIColor colorWithRed:0.25 green:0.0 blue:0.0 alpha:0.8];
		bottomLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0];
		bottomLabel.font = [UIFont systemFontOfSize:isiPad()?21:[UIFont labelFontSize] - 4];
        
        //
		// Create the label for the top row of text
		//
		detailLabel =
        [[[UILabel alloc]
          initWithFrame:
          CGRectMake(
                     listbg.size.width*2.2/5,
                     listbg.size.height*3/4-5,
                     tableView.bounds.size.width - listbg.size.width*2.2/5-(isiPad()?30:5),
                     listbg.size.height/4-5)]
         autorelease];
		[cell.contentView addSubview:detailLabel];
        
		//
		// Configure the properties for the text that are the same on every row
		//
		detailLabel.tag = DETAIL_LABEL_TAG;
		detailLabel.backgroundColor = [UIColor clearColor];
		detailLabel.textColor = [UIColor colorWithRed:0.25 green:0.0 blue:0.0 alpha:0.8];
		detailLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0];
		detailLabel.font = [UIFont systemFontOfSize:isiPad()?21:[UIFont labelFontSize] - 4];
        
		//
		// Create a background image view.
		//
		cell.backgroundView =
        [[[UIImageView alloc] init] autorelease];
	}
	else
	{
		topLabel = (UILabel *)[cell viewWithTag:TOP_LABEL_TAG];
		bottomLabel = (UILabel *)[cell viewWithTag:BOTTOM_LABEL_TAG];
        detailLabel = (UILabel *)[cell viewWithTag:DETAIL_LABEL_TAG];
	}
    
    AppRecord *appRecord = [dataset objectAtIndex:indexPath.row];
    
	topLabel.text = [appRecord.eObj objectForKey:@"title"];
	bottomLabel.text = [appRecord.eObj objectForKey:@"addr"];
	detailLabel.text = [NSString stringWithFormat:@"電話:%@",[appRecord.eObj objectForKey:@"tel"]];
    
	//
	// Set the background and selected background images for the text.
	// Since we will round the corners at the top and bottom of sections, we
	// need to conditionally choose the images based on the row index and the
	// number of rows in the section.
	// serialno
    ((UIImageView *)cell.backgroundView).image = listbg;
    if (!appRecord.appIcon)
    {
        if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
        {
            [self startIconDownload:appRecord forIndexPath:indexPath];
        }
        // if a download is deferred or in progress, return a placeholder image
        cell.imageView.image = [UIImage imageNamed:isiPad()?@"iconbg-ipad":@"iconbg"];
    }
    else
    {
        cell.imageView.image = appRecord.appIcon;
    }
    
	return cell;
    
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
