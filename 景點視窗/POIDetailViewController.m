//
//  HospitalDetailViewController.m
//  m-Order
//
//  Created by HSU CHIH YUAN on 12/8/8.
//  Copyright (c) 2012年 HSU CHIH YUAN. All rights reserved.
//

#import "POIDetailViewController.h"

@interface POIDetailViewController ()

@end

@implementation POIDetailViewController

@synthesize dataElement;

- (void)dealloc
{
    if (isInit) {
        webView.delegate = nil;
        [webView release];
        //request = nil;
        [dataElement release];
    }
	
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        // 在訂閱的部份，物件必須向 NSNotificationCenter 進行註冊，並且說明想要訂閱的訊息事件，和設定收到通知時要執行的函式，通常我們可以將訂閱的部份直接寫在物件初始化的地方，這樣物件在建立之後就可以立刻向 NSNotificationCenter 訂閱他所需要的資訊。
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(echoCollectionQRCode:) name:@"checkedCollectionQRCode" object:nil];
    }
    
    return self;
}

-(void)mapPathDirection:(id)sender
{
    DirectionsMap *myDirectionsMap = [[DirectionsMap alloc] init];
    
    [myDirectionsMap.view setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-navigationbarheight)];
    
    MKPointAnnotation* target = [[MKPointAnnotation alloc] init];
    target.title = [NSString stringWithFormat:@"%@", [dataElement objectForKey:@"title"]?[dataElement objectForKey:@"title"]:[dataElement objectForKey:@"name"]];
    target.coordinate = CLLocationCoordinate2DMake([[dataElement objectForKey:@"lat"] floatValue], [[dataElement objectForKey:@"lon"] floatValue]);
    
    [myDirectionsMap setPathDirection:target];
    [target release];
    
    [self.navigationController pushViewController:myDirectionsMap animated:YES];
    [myDirectionsMap release];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
}

-(void) backButtonTapped{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    
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
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"listbg"]]];
    
	// Do any additional setup after loading the view.
    isInit = NO;
    if (!isInit) {
        UIButton *btndirect =[[UIButton alloc] init];
        UIImage *btnway = [UIImage imageNamed:isiPad()?@"btn_way-ipad":@"btn_way"];
        [btndirect setBackgroundImage:btnway forState:UIControlStateNormal];
        btndirect.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-btnway.size.width, isiPad()?95:30, btnway.size.width, btnway.size.height);
        [btndirect addTarget:self action:@selector(mapPathDirection:) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem.titleView addSubview:btndirect];
        [btndirect release];
        //加入tableView
        mainView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-navigationbarheight)];
        mainView.backgroundColor = [UIColor clearColor];
        mainView.userInteractionEnabled=YES;
        mainView.showsVerticalScrollIndicator = NO;
        mainView.showsHorizontalScrollIndicator = NO;
        mainView.delegate = self;
        [mainView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"poibg"]]];
        
        headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, isiPad()?140:40)];
        [mainView addSubview:headerView];
        
        UIImageView *photo_bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, headerView.frame.size.height, [[UIScreen mainScreen] bounds].size.width, isiPad()?400:250)];
        [photo_bg setImage:[UIImage imageNamed:isiPad()?@"photo_bg-ipad":@"photo_bg"]];
        [mainView addSubview:photo_bg];
        [photo_bg release];
        
        //imageview
        unitimage = [[SWSnapshotStackView alloc] initWithFrame:CGRectMake(20, headerView.frame.size.height, [[UIScreen mainScreen] bounds].size.width-40, isiPad()?400:250)];
        unitimage.displayAsStack = YES;
        
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, unitimage.frame.size.height+unitimage.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-headerView.frame.size.height-unitimage.frame.size.height-navigationbarheight)];
        //[webView setScalesPageToFit:YES];
        webView.delegate = self;
        [webView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
        // Round corners using CALayer property
        [[webView layer] setCornerRadius:10];
        [webView setClipsToBounds:YES];
        
        // Create colored border using CALayer property
        [[webView layer] setBorderColor:
         [[UIColor colorWithRed:0.52 green:0.59 blue:0.57 alpha:0.5] CGColor]];
        [[webView layer] setBorderWidth:2.75];
        [mainView addSubview:unitimage];
        //內容背景
        [mainView addSubview:webView];
        [self.view addSubview:mainView]; // Add it as a subview of our main view
        
        
        [self performSelector:@selector(reloadObjectData) withObject:nil afterDelay:0.2];
        
        isInit = YES;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{   //發生錯誤
    [connect release];
	NSLog(@"發生錯誤");
    [progressAlert dismissWithClickedButtonIndex: 0  animated:YES];
    
    [unitimage removeFromSuperview];
    [webView setFrame:CGRectMake(0, headerView.frame.size.height, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-navigationbarheight-headerView.frame.size.height)];
}

- (void)connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)aResponse {  //連線建立成功
	expectedLength = [aResponse expectedContentLength]; //儲存檔案長度
}
-(void) connection:(NSURLConnection *)connection didReceiveData: (NSData *) incomingData
{   //收到封包，將收到的資料塞進緩衝中並修改進度條
	[tempData appendData:incomingData];
    
    double ex = expectedLength;
    [gsprg_Bar setProgress:([tempData length] / ex)];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (tempData && [tempData length]>0 && [UIImage imageWithData:tempData]) {
        unitimage.image = [UIImage imageWithData:tempData];
    }
    else{
        [unitimage removeFromSuperview];
        [webView setFrame:CGRectMake(0, headerView.frame.size.height, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-navigationbarheight-headerView.frame.size.height)];
    }
    [progressAlert dismissWithClickedButtonIndex: 0  animated:YES];
}

- (void)alertWaiting{
    progressAlert = [[UIAlertView alloc] initWithTitle:@"景點載入中"
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

#pragma 重新載入資料
- (void)reloadObjectData{
    if ([dataElement objectForKey:@"imageurl"] && ![[dataElement objectForKey:@"imageurl"] isEqualToString:@""]) {
        
        [self alertWaiting];
        
        //取得資料顯示圖片
        NSString *imageurl = [[NSString stringWithFormat:@"http://60.249.202.111/PTCulture/picDB/%@",[dataElement objectForKey:@"imageurl"]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        request = [[[NSMutableURLRequest alloc] init] autorelease];
        [request setURL:[NSURL URLWithString:imageurl]];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"Mobile Safari 1.1.3 (iPhone; U; CPU like Mac OS X; en)" forHTTPHeaderField:@"User-Agent"];
        tempData = [NSMutableData alloc];
        [request setTimeoutInterval:httptimeout];
        connect = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
    }
    else{
        [unitimage removeFromSuperview];
        [webView setFrame:CGRectMake(0, headerView.frame.size.height, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height-navigationbarheight-headerView.frame.size.height)];
    }
    
    NSString *strTemp = [NSString stringWithFormat:@"聯絡電話:%@<br>營業時間:%@<br>%@",[[dataElement objectForKey:@"tel"] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"],[[dataElement objectForKey:@"openhour"] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"],[[dataElement objectForKey:@"htmlcontent"] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"]];
    // HTML-based Presentation-only
    NSString *content=[NSString stringWithFormat:@"<html><body><table><tr><td><span style=\"color: green; font-size: 25px\"><b>%@</b></span></td></tr><tr><td><span style=\"font-size: 20px\">%@</span></td></tr></table></body></html>", [dataElement objectForKey:@"title"], strTemp];
    [webView loadHTMLString:content baseURL:nil];
    
}

- (void) webViewDidFinishLoad : (UIWebView *) aWebView
{
    CGRect frame = aWebView.frame;
    int height = frame.size.height;
    frame.size.height = 1;
    aWebView.frame = frame;
    CGSize fittingSize = [aWebView sizeThatFits:CGSizeZero];
    fittingSize.height = fittingSize.height<height?height:fittingSize.height;
    frame.size = fittingSize;
    aWebView.frame = frame;
    
    ////NSLog(@"size: %f, %f", fittingSize.width, fittingSize.height);
    
    [mainView setContentSize:CGSizeMake(self.view.frame.size.width,  webView.frame.origin.y+webView.frame.size.height)];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
