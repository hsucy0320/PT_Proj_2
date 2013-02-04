//
//  iCarouselViewController.h
//  i高醫
//
//  Created by hsucy0320 on 2011/10/14.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
#import "MWPhoto.h"
#import "MWPhotoBrowser.h"

#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
#include <arpa/inet.h>
#include <netdb.h>
#import "DirectionsMap.h"
#import "KGDiscreetAlertView.h"
#import "GSProgressView.h"

@interface iCarouselViewController : UIViewController<iCarouselDataSource, iCarouselDelegate> {
    iCarousel *carousel;
    NSMutableArray	*tempViews;
    UIActivityIndicatorView *spinner; 
    UIActivityIndicatorView *btnspinner;
    BOOL isPlay;
    UILabel *lblTitle;
    BOOL bChange;
    UITextView *txtView;
    NSString * _voicefn;
    UIScrollView *scroller;
    GSProgressView *gsprg_Bar;
    NSURLConnection* connection; //keep a reference to the connection so we can cancel download in dealloc
	NSMutableData* imgdata; //keep reference to the data so we can collect it as it downloads
	//but where is the UIImage reference? We keep it in self.subviews - no need to re-code what we have in the parent class
    int imageindex;
    BOOL flag;
    // 
    NSDictionary *_poiObj;
    NSMutableArray *_poiImages;
    
    //http
    NSMutableData *tempData;    //下載時暫存用的記憶體
    long expectedLength;        //檔案大小
    NSURLConnection *connect;
    UIAlertView *progressAlert;
    BOOL isAsycBtn;
    BOOL bfullLoading;
}

#pragma Host Function
- (BOOL)addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)address;
- (NSString *) getIPAddressForHost: (NSString *) theHost;
- (BOOL) hostAvailable: (NSString *) theHost;

- (void)loadImageFromURL:(NSURL*)url;
- (UIImage*) imageByScalingToSize:(CGSize) targetSize sourceImage:(UIImage*)sourceImage;
@property (nonatomic, retain) iCarousel *carousel;
@property (nonatomic, retain) NSDictionary *poiObj;
@property (nonatomic, retain) NSMutableArray *poiImages;
//- (BOOL) getAllGaleryFromDB;
- (void) initView;
- (void)setViewDidLoad;

@end
