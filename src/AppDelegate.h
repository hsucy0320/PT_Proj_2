//
//  AppDelegate.h
//  m-Order
//
//  Created by HSU CHIH YUAN on 12/8/1.
//  Copyright (c) 2012年 HSU CHIH YUAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "LiteMainPageViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    UINavigationController *navController;
    //http
    ASIFormDataRequest *requestObj;
}

#pragma Host Function
- (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)address;
- (NSString *) getIPAddressForHost: (NSString *) theHost;
- (BOOL) hostAvailable: (NSString *) theHost;
- (void)getAuthenticationData:(NSString*)deviceToken;

@property (nonatomic, retain) UINavigationController *navController;
@property (strong, nonatomic) UIWindow *window;

@end
