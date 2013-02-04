//
//  AppDelegate.m
//  m-Order
//
//  Created by HSU CHIH YUAN on 12/8/1.
//  Copyright (c) 2012年 HSU CHIH YUAN. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize navController;

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

-(void) getNetworkStatus{
# pragma 取得網路狀態
    //Create zero addy
    struct sockaddr_in Addr;
    bzero(&Addr, sizeof(Addr));
    Addr.sin_len = sizeof(Addr);
    Addr.sin_family = AF_INET;
    
    //結果存至旗標中
    SCNetworkReachabilityRef target = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &Addr);
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityGetFlags(target, &flags);
    
    //將取得結果與狀態旗標位元做AND的運算並輸出
    if (flags & kSCNetworkFlagsReachable)
    {
#ifdef DEBUG
        NSLog(@"無線網路狀態ok");
#endif
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"wifi"];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"wifi"];
    }
    
    if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
#ifdef DEBUG
        NSLog(@"電信網路狀態ok");
#endif
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"gprs"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"gprs"];
    }
}

//建議不要再使用DeviceID
- (NSString *) uuid
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *uuid = [NSString stringWithString:(NSString *)
                      uuidStringRef];
    CFRelease(uuidStringRef);
    return uuid;
}

//Best way to serialize a NSData into an hexadeximal string
-(NSString*) serializeDeviceToken:(NSData*) deviceToken
{
    NSMutableString *str = [NSMutableString stringWithCapacity:64];
    int length = [deviceToken length];
    char *bytes = malloc(sizeof(char) * length);
    
    [deviceToken getBytes:bytes length:length];
    
    for (int i = 0; i < length; i++)
    {
        [str appendFormat:@"%02.2hhX", bytes[i]];
    }
    free(bytes);
    
    return str;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    LiteMainPageViewController *myLiteMainPageViewController = [[LiteMainPageViewController alloc] init];
    [myLiteMainPageViewController.view setFrame:[[UIScreen mainScreen] bounds]];
    navController = [[UINavigationController alloc] initWithRootViewController:myLiteMainPageViewController];
    [myLiteMainPageViewController release];
    
    navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    [[self window] setRootViewController:self.navController];
    
    // as usual
    [self.window makeKeyAndVisible];
    //防止 Device 自動進入待機狀態
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    return YES;
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

#pragma HTTP Function
- (void)getAuthenticationData:(NSString*)deviceToken {
    
    if ([self hostAvailable:weburi]){
        //資料載入
        requestObj = nil;
        NSString *percentEscapedString = [[NSString stringWithFormat:@"http://%@:%@/PTCulture/ws/updateMachine?t=%@&os=ios", weburi, webport, deviceToken]  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"tokenString=%@",percentEscapedString);
        
        requestObj = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:percentEscapedString]];
        [requestObj setRequestMethod:@"GET"];
        [requestObj setTimeOutSeconds:httptimeout];
        [requestObj setDelegate:self];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"wifi"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"gprs"]) {
            //do smth
            // http service
            [requestObj startAsynchronous];
        }
        else
        {
            NSLog(@"設備網路服務異常。");
        }
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    if ([request responseString]) {
        NSLog(@"%@",[request responseString]);
    }
}

-(NSString*)getDeviceToken{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //1
    //NSLog(@"paths=%@",paths);
    NSString *documentsDirectory = [paths objectAtIndex:0]; //2
    //NSLog(@"documentsDirectory=%@",documentsDirectory);
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"config.plist"]; //3
    //NSLog(@"path1=%@",path);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if (![fileManager fileExistsAtPath: path]) //4
    {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"]; //5
        
        [fileManager copyItemAtPath:bundle toPath: path error:&error]; //6
    }
    //NSLog(@"path2=%@",path);
    NSMutableDictionary *savedStock = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
    NSString *deviceToken = [[[savedStock objectForKey:@"deviceToken"] retain] autorelease];
    [savedStock release];
    //NSLog(@"weight=%@",temp);
    return deviceToken;
}

- (BOOL)isEmptyString:(NSString *)string
// Returns YES if the string is nil or equal to @""
{
    // Note that [string length] == 0 can be false when [string isEqualToString:@""] is true, because these are Unicode strings.
    
    if (((NSNull *) string == [NSNull null]) || (string == nil) ) {
        return YES;
    }
    string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([string isEqualToString:@""]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - APNS Format
/*
 {
 "aps": {
 "alert" : "You got a new message!" ,
 "badge" : 5,
 "sound" : "beep.wav"},
 "acme1" : "bar",
 "acme2" : 42
 }
 */

- ( void )application:(UIApplication * )application didRegisterForRemoteNotificationsWithDeviceToken:(NSData * )deviceToken
{
#if !TARGET_IPHONE_SIMULATOR
    NSLog( @" My token is: %@ " , deviceToken);
    //[self getAuthenticationData:[self serializeDeviceToken:deviceToken]];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //1
    NSString *documentsDirectory = [paths objectAtIndex:0]; //2
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"config.plist"]; //3
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath: path]) //4
    {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"]; //5
        
        [fileManager copyItemAtPath:bundle toPath: path error:&error]; //6
    }
    NSMutableDictionary *savedStock = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
    //儲存weight
    [savedStock setObject:[self serializeDeviceToken:deviceToken] forKey:@"deviceToken"];
	[savedStock writeToFile:path atomically: YES];
    [savedStock release];
#endif
}

- ( void )application:(UIApplication * )application didFailToRegisterForRemoteNotificationsWithError:(NSError * )error
{
    NSLog( @" Failed to get token, error: %@ " , [error localizedDescription]);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:( NSDictionary *)userInfo {
#if !TARGET_IPHONE_SIMULATOR
    NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
    
    if (apsInfo) {
        if ([apsInfo objectForKey:@"alert"]) {
            // 收到訊息進行處理
            [[NSNotificationCenter defaultCenter] postNotificationName:@"echoNotificationEvent" object:[NSArray arrayWithObjects:apsInfo, nil]];
        }
    }
#endif
}

//休眠后委托事件
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    //防止 Device 自動進入待機狀態
    //[UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

//程序喚醒後要執行的事件
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self getNetworkStatus];
}

#define kMyNotificationTerminate @"MyNotificationTerminate"  

// 在这里完成程序將要關閉的事情 
- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
