//
//  HospitalViewController.h
//  m-Order
//
//  Created by HSU CHIH YUAN on 12/8/3.
//  Copyright (c) 2012年 HSU CHIH YUAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBJsonParser.h"
#import "KGDiscreetAlertView.h"
#import "iCarouselViewController.h"
#import "POIDetailViewController.h"

#import "ASIFormDataRequest.h"

#pragma mark - Host
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <QuartzCore/QuartzCore.h>
#import "GSProgressView.h"

#import "REVClusterMapView.h"
#import "REVClusterMap.h"
#import "REVClusterAnnotationView.h"

@interface MapViewController : UIViewController<MKMapViewDelegate, UIAlertViewDelegate>
{
    BOOL isInit;
    NSMutableArray * dataset;
    UIAlertView *progressAlert;
    
    //Map
    REVClusterMapView *mapView;
    
    //http
    ASIFormDataRequest *requestObj;
    BOOL httpSemaphore;
    NSMutableString *jsonContent;
    BOOL clickSemaphore;
    
    //ASINetworkQueue *queue;
    NSString *downloadPath;
    NSString *unzipPath;
    GSProgressView *gsprg_Bar;
    UIImage *bgimageColor;
    NSMutableURLRequest *requestUpdate;
    NSMutableData *tempData;    //下載時暫存用的記憶體
    long expectedLength;        //檔案大小
    NSURLConnection *connect;
    NSArray *paths;
    NSString *_strweight;
    NSString *documentsDirectory;
    NSString *path;
    NSFileManager *fileManager;
    NSString *bundle;
    NSMutableDictionary *savedStock;
}

- (void)getDataFromWSInterface;
#pragma mark - 轉換poi to mkannotation
- (void)mapKitData;

- (MKMapRect) getMapRectUsingAnnotations : (NSMutableArray *)data;
@property (nonatomic, retain) NSMutableArray * dataset;

#pragma Host Function
- (BOOL) addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)address;
- (NSString *) getIPAddressForHost: (NSString *) theHost;
- (BOOL) hostAvailable: (NSString *) theHost;
- (void)getUpdateData;
- (void)updateAlertWaiting;
- (void)alertWaiting;

@end
