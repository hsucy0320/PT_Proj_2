//
//  LiteMainPageViewController.h
//  PTCAD
//
//  Created by HSU CHIH YUAN on 12/12/18.
//  Copyright (c) 2012年 HSU CHIH YUAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ListViewController.h"
#import "MapViewController.h"

@interface LiteMainPageViewController : UIViewController
{
    ListViewController *myListViewController;
    MapViewController *myMapViewController;
}

@end
