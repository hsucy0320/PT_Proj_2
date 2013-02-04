//
//  HospitalDetailViewController.h
//  m-Order
//
//  Created by HSU CHIH YUAN on 12/8/8.
//  Copyright (c) 2012年 HSU CHIH YUAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBJsonParser.h"
#import "KGDiscreetAlertView.h"
#import "SWSnapshotStackView.h"
#import "DirectionsMap.h"
#import <QuartzCore/QuartzCore.h>
#import "GSProgressView.h"

@interface POIDetailViewController : UIViewController<UIScrollViewDelegate, UIWebViewDelegate>
{
    BOOL isInit;
    NSMutableDictionary *dataElement;
    SWSnapshotStackView *unitimage;
    UIScrollView* mainView;
    UIWebView *webView;
    NSMutableURLRequest *request;
    NSMutableData *tempData;    //下載時暫存用的記憶體
    long expectedLength;        //檔案大小
    NSURLConnection *connect;
    UIAlertView *progressAlert;
    GSProgressView *gsprg_Bar;
    UIView *headerView;
}

- (void)reloadObjectData;
@property (nonatomic, retain) NSMutableDictionary *dataElement;

@end
