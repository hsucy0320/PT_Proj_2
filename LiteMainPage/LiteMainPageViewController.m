//
//  LiteMainPageViewController.m
//  PTCAD
//
//  Created by HSU CHIH YUAN on 12/12/18.
//  Copyright (c) 2012年 HSU CHIH YUAN. All rights reserved.
//

#import "LiteMainPageViewController.h"

@interface LiteMainPageViewController ()

@end

@implementation LiteMainPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    
    UIImage *image = [UIImage imageNamed:isiPad()?@"menu_bg-ipad":iPhone568ImageNamed(@"menu_bg")];
    UIImageView *myimageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -navigationbarheight, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    [myimageView setImage:image];
    [self.view addSubview:myimageView];
    [myimageView release];
    //客制化標頭文字
    UIImage *headerimage = [UIImage imageNamed:isiPad()?@"header_bg-ipad":@"header_bg"];
    UIImageView *header = [[UIImageView alloc] initWithImage:headerimage];
    [header setFrame:CGRectMake(isiPad()?-7:-5, isiPad()?80:20, headerimage.size.width, headerimage.size.height)];
    CGRect frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, headerimage.size.height);
    UIView *myheader = [[UIView alloc] init];
    [myheader addSubview:header];
    [myheader setBackgroundColor:[UIColor clearColor]];
    [myheader setFrame:frame];
    self.navigationItem.titleView = myheader;
    
    [header release];
    [myheader release];
    
    UIImage *listimage = [UIImage imageNamed:isiPad()?@"menu_list-ipad":@"menu_list"];
    UIButton *btnList = [[UIButton alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width/10, [[UIScreen mainScreen] bounds].size.height/4.5-navigationbarheight, listimage.size.width, listimage.size.height)];
    [btnList setBackgroundImage:listimage forState:UIControlStateNormal];
    [btnList addTarget:self action:@selector(function_clicked:) forControlEvents:UIControlEventTouchUpInside];
    [btnList setShowsTouchWhenHighlighted:YES];
    [btnList setTag:0];
    //設定轉角
    [[btnList layer] setCornerRadius:8.0f];
    [btnList.layer setMasksToBounds:YES];
    [btnList.layer setBorderWidth:0.0f];
    [btnList.layer setBorderColor:[UIColor grayColor].CGColor];
    [self.view addSubview:btnList];
    [btnList release];
    
    UIImage *mapimage = [UIImage imageNamed:isiPad()?@"menu_map-ipad":@"menu_map"];
    UIButton *btnMap = [[UIButton alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height/2-navigationbarheight, mapimage.size.width, mapimage.size.height)];
    [btnMap setBackgroundImage:mapimage forState:UIControlStateNormal];
    [btnMap addTarget:self action:@selector(function_clicked:) forControlEvents:UIControlEventTouchUpInside];
    [btnMap setShowsTouchWhenHighlighted:YES];
    [btnMap setTag:1];
    btnMap.transform = CGAffineTransformMakeRotation(0);
    //設定轉角
    [[btnMap layer] setCornerRadius:8.0f];
    [btnMap.layer setMasksToBounds:YES];
    [btnMap.layer setBorderWidth:0.0f];
    [btnMap.layer setBorderColor:[UIColor grayColor].CGColor];
    [self.view addSubview:btnMap];
    [btnMap release];
    
}

- (void)function_clicked:(id)sender{
    switch (((UIButton*)sender).tag) {
        case 0:
            myListViewController = [[ListViewController alloc] init];
            [myListViewController.view setFrame:[[UIScreen mainScreen] bounds]];
            [myListViewController getDataFromWSInterface];
            [self.navigationController pushViewController:myListViewController animated:YES];
            [myListViewController release];
            break;
        case 1:
            myMapViewController = [[MapViewController alloc] init];
            [myMapViewController.view setFrame:[[UIScreen mainScreen] bounds]];
            [myMapViewController getDataFromWSInterface];
            [self.navigationController pushViewController:myMapViewController animated:YES];
            [myMapViewController release];
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //系統默認不支持旋轉功能
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
