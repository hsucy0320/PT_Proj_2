//
//  DirectionsExample.h
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

#pragma mark - Host
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MapKit/MapKit.h>
#import "KGDiscreetAlertView.h"
#import "StringHelper.h"
#import "ASIFormDataRequest.h"

@interface DirectionsMap : UIViewController<UIAlertViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate>
{
    BOOL isInit;
    UIAlertView *progressAlert;
    ASIFormDataRequest *requestObj;
    BOOL httpSemaphore;
    BOOL gpsSemaphore;
    CLLocationManager *locmanager;
}

@property(nonatomic, retain) id<MKAnnotation> source;
@property(nonatomic, retain) id<MKAnnotation> destination;
@property(nonatomic, retain) MKPolyline* routeLine;
@property (nonatomic, retain) MKMapView* map;
@property (nonatomic, retain) CLLocationManager *locmanager;

- (void) setRoutePoints:(NSArray*)locations;
- (void)setPathDirection:(MKPointAnnotation*) target;
- (void)caculatedPath;
- (NSMutableArray *)decodePolyLine:(NSMutableString *)encoded;

@end
